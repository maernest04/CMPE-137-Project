# CMPE-137-Project
# Spartan Space

Spartan Space is a mobile application project for San Jose State University students to discover, review, and navigate to study spaces across campus. The app is designed to help students find study spots that match their preferences by combining location information, user reviews, ratings, and map-based navigation.

## Project Overview

Many students struggle to find study spaces that fit their needs. Popular areas can become crowded, while other useful study spaces may go unnoticed. Spartan Space aims to solve this by providing a platform where students can:

- Discover study spaces across campus
- Add study spaces for others to access
- Read and leave reviews about study locations
- View ratings for factors such as noise level, comfort, and power outlet availability
- Receive recommendations based on preferences
- Navigate to study spaces using mapping tools such as Google Maps and Apple Maps

## Scope

This project is a **study space locating platform**, not a room reservation system. Its main purpose is to help users find ideal study environments using location details, reviews, ratings, and recommendations. The application will provide a directory of study spaces across campus and allow filtering or recommendation based on user preferences.

### Example Study Space Types

The current plan mentions that study spaces may include:

- Dr. Martin Luther King Jr. Library study rooms or floors
- Building study areas
- Student Union study areas such as cafeterias, success centers, and lounges
- Classrooms that are often vacant or are dedicated workspaces
## Features

### Planned Features

- Study space discovery
- Study space directory/listing
- Study space detail pages
- User reviews and ratings
- Study space recommendations
- Navigation to locations through map apps

### Study Space Information

Each study space is planned to include:

- Photo of location
- Building name
- Area information (such as room number or table location)
- Floor number
- Amount of seating
- Power outlet availability

### Review Criteria

Each study space will support a review/rating system that includes:

- Noise level
- Comfort
- Crowd level
- Ease of access

## User Flow

The current user flow described in the design document is:

1. Open the application
2. View suggested study spaces
3. Browse available study spaces by scrolling or filtering by preference
4. Open a study space to view details such as location, reviews, ratings, and sound level
5. Select directions to the study space
6. Open Apple Maps or Google Maps for navigation
7. Leave a review after using the study

## Architecture

The design document describes the system in three layers:

### 1. Client Layer
This is where the user interacts with the application. Users access study space information, submit reviews, and get directions.

### 2. Application Layer
This layer processes user requests and retrieves information. It includes handling reviews, providing study space location data, and communicating with map APIs.

### 3. Database Layer
This layer stores application data, including study space information, ratings, and reviews, and supports backend retrieval and updates.

## Technology

The document explicitly mentions:

- **Frontend / Mobile App:** Flutter
- **Database:** Firebase
- **Map integration:** Google Maps and Apple Maps 

### Information Needed
The following technical details are not fully specified in the plan and should be added by the team:

- TODO: Final database choice
- TODO: Backend framework / service choice
- TODO: Authentication approach
- TODO: State management approach in Flutter
- TODO: API/services used for recommendations
- TODO: Deployment targets (iOS, Android, or both)
- TODO: Minimum supported OS versions

## Team

The project document lists the following work distribution:

- **Paul Brandon Estigoy** — 
- **Raghav Gautam** — 
- **Ernest Ma** — 
- **Colin Oliva** — Full stack integration and map implementation

## Design Goals

The project emphasizes a simple and straightforward user experience. The design aims to show only essential information for study spaces instead of overwhelming users. Reviews and ratings are intended to improve engagement by helping students benefit from real student feedback. The document also states an expectation for fast database access and minimal delay.

## Competitive / Problem Context

The project identifies a gap in current SJSU study space solutions:

- Existing SJSU systems focus on reserving library study rooms only
- Existing map app reviews for buildings are often too general or not relevant to the student study experience
- Spartan Space aims to provide more targeted information for study-specific decision-making across campus

## Project Status

**Current status:** Planning / design phase based on the project design document.

## Setup

.

### TODO
Add:

- repository clone instructions
- dependency installation steps
- Flutter setup instructions
- environment variable configuration
- Firebase setup steps
- map API key configuration
- run instructions for local development

Example placeholder section:

```bash
# TODO: add actual setup commands
git clone <your-repository-url>
cd <your-project-folder>
flutter pub get
flutter run