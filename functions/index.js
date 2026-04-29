const functions = require('firebase-functions');
const admin = require('firebase-admin');
const cors = require('cors')({ origin: true });

admin.initializeApp();
const db = admin.firestore();

async function recalculateSpaceAverages(spaceId) {
  const reviewsCol = db.collection('spaces').doc(spaceId).collection('reviews');
  const snap = await reviewsCol.get();
  const spaceRef = db.collection('spaces').doc(spaceId);

  if (snap.empty) {
    await spaceRef.set(
      {
        noiseLevelAvg: 0,
        comfortAvg: 0,
        crowdLevelAvg: 0,
        accessAvg: 0,
        overallAvg: 0,
        reviewCount: 0,
      },
      { merge: true },
    );
    return;
  }

  let noise = 0;
  let comfort = 0;
  let crowd = 0;
  let access = 0;
  let overall = 0;
  let overallCount = 0;
  snap.forEach((d) => {
    const r = d.data();
    noise += r.noiseLevel || 0;
    comfort += r.comfort || 0;
    crowd += r.crowdLevel || 0;
    access += r.easeOfAccess || 0;
    if (r.overallRating) {
      overall += r.overallRating;
      overallCount++;
    }
  });
  const n = snap.size;
  const noiseA = noise / n;
  const comfortA = comfort / n;
  const crowdA = crowd / n;
  const accessA = access / n;

  await spaceRef.set(
    {
      noiseLevelAvg: noiseA,
      comfortAvg: comfortA,
      crowdLevelAvg: crowdA,
      accessAvg: accessA,
      overallAvg: overallCount > 0 ? overall / overallCount : (noiseA + comfortA + crowdA + accessA) / 4.0,
      reviewCount: n,
    },
    { merge: true },
  );
}

// Recompute space aggregates on any review create, update, or delete.
// (Replaces the previous onCreate-only trigger so edits/deletes stay correct.)
exports.recalculateAveragesOnCreate = functions.firestore
  .document('spaces/{spaceId}/reviews/{reviewId}')
  .onWrite(async (change, context) => {
    const { spaceId } = context.params;
    await recalculateSpaceAverages(spaceId);
    return null;
  });

// HTTP endpoint to accept reviews from clients and write to Firestore.
exports.submitReview = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    if (req.method !== 'POST') {
      return res.status(405).send({ error: 'Method not allowed, use POST.' });
    }

    const authHeader = req.get('Authorization') || req.get('authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).send({
        error: 'Missing Authorization header. Send Firebase ID token as Bearer token.',
      });
    }

    const idToken = authHeader.split('Bearer ')[1];
    let uid = null;
    let userNameFromToken = null;
    try {
      const decoded = await admin.auth().verifyIdToken(idToken);
      uid = decoded.uid;
      userNameFromToken = decoded.name || decoded.email || null;
    } catch (err) {
      console.error('ID token verification failed', err);
      return res.status(401).send({ error: 'Invalid ID token' });
    }

    const body = req.body || {};
    const { spaceId, noiseLevel, comfort, crowdLevel, easeOfAccess, overallRating, comment } = body;

    if (!spaceId) {
      return res.status(400).send({ error: 'spaceId is required' });
    }

    const toInt = (v) => {
      const n = Number(v);
      return Number.isFinite(n) ? Math.round(n) : null;
    };

    const noise = toInt(noiseLevel);
    const conf = toInt(comfort);
    const crowd = toInt(crowdLevel);
    const access = toInt(easeOfAccess);
    const overall = toInt(overallRating);

    if ([noise, conf, crowd, access, overall].some((v) => v === null || v < 1 || v > 5)) {
      return res.status(400).send({ error: 'Ratings must be integers between 1 and 5.' });
    }

    try {
      const reviewsRef = db.collection('spaces').doc(spaceId).collection('reviews');
      const newRef = reviewsRef.doc();

      await newRef.set({
        userId: uid,
        userName: userNameFromToken || 'Anonymous',
        noiseLevel: noise,
        comfort: conf,
        crowdLevel: crowd,
        easeOfAccess: access,
        overallRating: overall,
        comment: comment || '',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      await recalculateSpaceAverages(spaceId);

      return res.status(200).send({ success: true, id: newRef.id });
    } catch (err) {
      console.error('submitReview error', err);
      return res.status(500).send({ error: 'Internal server error' });
    }
  });
});
