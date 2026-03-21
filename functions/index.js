const functions = require('firebase-functions');
const admin = require('firebase-admin');
const cors = require('cors')({ origin: true });

admin.initializeApp();
const db = admin.firestore();

// Recalculate space aggregates when a new review is created.
exports.recalculateAveragesOnCreate = functions.firestore
  .document('spaces/{spaceId}/reviews/{reviewId}')
  .onCreate(async (snap, context) => {
    const { spaceId } = context.params;
    const review = snap.data();

    const spaceRef = db.collection('spaces').doc(spaceId);

    await db.runTransaction(async (tx) => {
      const spaceDoc = await tx.get(spaceRef);
      const current = spaceDoc.exists ? spaceDoc.data() : {};

      const prevCount = (current && current.reviewCount) ? current.reviewCount : 0;

      const prevNoise = (current && current.noiseLevelAvg) ? current.noiseLevelAvg : 0;
      const prevComfort = (current && current.comfortAvg) ? current.comfortAvg : 0;
      const prevCrowd = (current && current.crowdLevelAvg) ? current.crowdLevelAvg : 0;
      const prevAccess = (current && current.accessAvg) ? current.accessAvg : 0;

      const newCount = prevCount + 1;

      const newNoise = ((prevNoise * prevCount) + (review.noiseLevel || 0)) / newCount;
      const newComfort = ((prevComfort * prevCount) + (review.comfort || 0)) / newCount;
      const newCrowd = ((prevCrowd * prevCount) + (review.crowdLevel || 0)) / newCount;
      const newAccess = ((prevAccess * prevCount) + (review.easeOfAccess || 0)) / newCount;

      const newOverall = (newNoise + newComfort + newCrowd + newAccess) / 4.0;

      tx.set(spaceRef, {
        noiseLevelAvg: newNoise,
        comfortAvg: newComfort,
        crowdLevelAvg: newCrowd,
        accessAvg: newAccess,
        overallAvg: newOverall,
        reviewCount: newCount,
      }, { merge: true });
    });

    return null;
  });

  // HTTP endpoint to accept reviews from clients and write to Firestore.
  exports.submitReview = functions.https.onRequest((req, res) => {
    return cors(req, res, async () => {
      // Allow only POST
      if (req.method !== 'POST') {
        return res.status(405).send({ error: 'Method not allowed, use POST.' });
      }

      // Require Firebase ID token in Authorization header (Bearer <token>)
      const authHeader = req.get('Authorization') || req.get('authorization');
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).send({ error: 'Missing Authorization header. Send Firebase ID token as Bearer token.' });
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
      const {
        spaceId,
        noiseLevel,
        comfort,
        crowdLevel,
        easeOfAccess,
        comment,
      } = body;

      if (!spaceId) {
        return res.status(400).send({ error: 'spaceId is required' });
      }

      // Basic validation and casting
      const toInt = (v) => {
        const n = Number(v);
        return Number.isFinite(n) ? Math.round(n) : null;
      };

      const noise = toInt(noiseLevel);
      const conf = toInt(comfort);
      const crowd = toInt(crowdLevel);
      const access = toInt(easeOfAccess);

      if ([noise, conf, crowd, access].some((v) => v === null || v < 1 || v > 5)) {
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
          comment: comment || '',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        return res.status(200).send({ success: true, id: newRef.id });
      } catch (err) {
        console.error('submitReview error', err);
        return res.status(500).send({ error: 'Internal server error' });
      }
    });
  });
