# ReCircle

**Nothing Ends. It Transforms.** — Reuse First, Recycle When Needed.

ReCircle is a Flutter e-waste collection MVP backed by a Node.js/Express REST API and MongoDB. The customer and collection partner use the same persistent request record. Image analysis uses an authenticated Gemini-backed API; rewards remain demo-only.

## Repository audit and implementation plan

The Flutter app includes ReCircle branding, home/navigation, camera/gallery capture, item analysis, reuse guides, impact/reward screens and pickup tracking UI. Before API wiring, pickups were initialized with sample data, request IDs and status progress were generated locally, and bookings lasted only for the current process. The `payroll-desk-android/` folder is an unrelated existing project and is left untouched. The repository started with numerous uncommitted app, branding, Android, and test changes; these were preserved.

Implementation is prioritized as: (1) API/configuration and docs, (2) Mongo models and tests, (3) authentication and roles, (4) persistent customer requests, (5) partner claim/status workflow, (6) Flutter integration, and (7) security and demo checks. A MongoDB URI is required for a live shared demonstration. No credentials are included.

## Architecture

- `lib/`: existing Flutter application, with the ReCircle screens and camera/reuse functionality.
- `backend/`: independently runnable Express API. MongoDB is accessed only by this API.
- `GET /api/v1/health`: safe liveness endpoint.
- Request lifecycle: `Submitted → Accepted → Collected → ReceivedForProcessing → Completed`. The partner who atomically accepts a request is the only partner who can update it. Customers can read their own requests. Status history is stored on the request.

## Backend setup

Requirements: Node.js 20 or newer and MongoDB (local MongoDB or MongoDB Atlas). From `backend/`:

```sh
npm install
```

If `.env` does not exist, create it from `.env.example` (`Copy-Item .env.example .env` in PowerShell). If it already exists, add or update only the needed entries; do not replace the file. Set the MongoDB URI, a random JWT secret of at least 32 characters, a separate random partner setup key, and Gemini configuration described below. Keep `.env` private; it is gitignored. For Atlas, create a database user with a strong password and allow the demo host's IP in Network Access. Never put the URI, JWT secret, or Gemini key in Flutter.

### Gemini image analysis

Add `GEMINI_API_KEY` to `backend/.env` from a Google AI Studio API key; do not put it in Flutter or commit it. `GEMINI_MODEL` defaults to `gemini-3.8-flash`. Restart the backend after changing environment settings. The authenticated `POST /api/v1/analysis` endpoint accepts raw JPG, PNG, or WebP bytes, validates the image signature and an 8 MB limit, calls Gemini with JSON output, validates the structured result, and stores only the result and user ID in MongoDB. `GET /api/v1/analysis/history` returns at most 50 analyses for the authenticated customer. Uploaded image bytes are not stored. Provider failures are returned as safe errors; no sample result is substituted. The endpoint allows 10 analyses per customer per 15 minutes.

Run `npm start` (or `npm run dev` for Node's watch mode). Check `http://localhost:3000/api/v1/health`. Run backend tests with `npm test`; they use an in-memory MongoDB and need no Atlas database. On the first test run, `mongodb-memory-server` downloads the MongoDB 7.0 test binary (about 600 MB on Windows) into the ignored `backend/.mongo-cache/` directory.

### Demo partner account

There is intentionally no public partner registration. With the API running and `PARTNER_SETUP_KEY` configured, create a demo partner from a trusted terminal:

```sh
curl -X POST http://localhost:3000/api/v1/auth/partner-setup \
  -H 'Content-Type: application/json' \
  -H 'x-partner-setup-key: YOUR_PARTNER_SETUP_KEY' \
  -d '{"name":"Demo Partner","email":"partner@example.com","password":"Use-A-Strong-Demo-Password"}'
```

Keep the setup key private and rotate/remove it after account creation. Customer registration is available through the app/API. Partner login uses the same login endpoint and role returned by the server.

## Flutter API configuration and networking

`API_BASE_URL` is the single API root used by authentication, analysis, history, and pickup workflows. In debug builds only, the default remains `http://10.0.2.2:3000/api/v1` for the Android emulator. Supply another developer URL explicitly with `flutter run --dart-define=API_BASE_URL=http://<developer-host>:3000/api/v1`. Android cleartext access is enabled only in the debug manifest.

Release builds have no local URL fallback. They require `--dart-define=API_BASE_URL=https://<your-host>/api/v1`; the app shows a configuration error on startup if the value is missing, malformed, not rooted at `/api/v1`, or not HTTPS. Build only after deploying the backend and use the service's actual HTTPS URL. Do not put MongoDB, JWT, Gemini, or partner setup secrets in this define.

## Production deployment (Atlas + Render example)

1. In MongoDB Atlas, create a project and a dedicated database deployment. Create a database user with a unique strong password and access limited to the `recircle` database (read/write only). Put the password into the URI through the dashboard's connection string flow and URL-encode reserved characters. Keep this URI private.
2. In Atlas **Network Access**, allow the backend host's documented outbound IP addresses. If your hosting plan does not provide fixed outbound addresses, use the narrowest supported network option and understand that allowing `0.0.0.0/0` permits connection attempts from anywhere; Atlas still requires database credentials. Do not use that broad rule when a narrower host egress range is available.
3. Create a Render **Web Service** from this GitHub repository. Set its root directory to `backend`, runtime to Node, build command to `npm ci`, and start command to `npm start`. Use a Node version satisfying `>=20`.
4. In the Render service's Environment settings, set `MONGODB_URI` (Atlas connection string with database name `recircle`), `JWT_SECRET` (random, at least 32 characters), `GEMINI_API_KEY`, and `PARTNER_SETUP_KEY` (separate random value). Optionally set `JWT_EXPIRES_IN`, `GEMINI_MODEL`, and `CORS_ORIGINS` as comma-separated exact origins if a browser client needs API access. Flutter native requests generally have no browser Origin. Never paste secret values into source control or chat; generate and enter them directly in the provider dashboards. `PORT` is supplied by Render.
5. Deploy and wait for the service to become healthy. Open `https://<service-host>/api/v1/health`. A healthy response reports `status: ok` and `database: connected`; it never returns the URI or credentials. A 503 means the backend cannot reach MongoDB.
6. In the repository root, run `flutter pub get`, then build an installable release APK with the real URL:

   ```powershell
   flutter build apk --release --dart-define=API_BASE_URL=https://<service-host>/api/v1
   ```

   The APK is at `build/app/outputs/flutter-apk/app-release.apk`. A debug APK is intended for development and debugging; a release APK is optimized and does not permit the debug-only cleartext exception. This repository currently signs release builds with the Android debug key. That is adequate for a temporary private installation, but not for secure long-term updates/distribution; configure your own protected release keystore and signing properties locally before distributing. Never commit the keystore or passwords.
7. Transfer the APK to the phone (USB file transfer, cloud drive, or another trusted method) and install it. Android may ask you to allow installs from that specific transfer app. Open ReCircle, register/sign in, analyze an item, open Analysis History, and create a pickup request.
8. Turn off USB debugging, stop the laptop backend, and repeat on mobile data or a different Wi-Fi network. These checks establish that the app uses the hosted backend. Do not treat a successful build or local health check as proof of this end-to-end test.

### Existing local data

Atlas starts as a separate database; this deployment does not alter or delete the local database. If existing development records are needed, take a verified backup first and migrate only the required collections with `mongodump`/`mongorestore` using separately protected local and Atlas URIs. Test the restored data in a separate Atlas database before pointing a live service at it. Do not overwrite the existing local database.

## API reference

All endpoints are under `/api/v1`. Protected endpoints use `Authorization: Bearer <token>`. Responses use `{ "success": true, "data": ... }`; errors use `{ "success": false, "error": { "message": ... } }`.

| Method | Path | Access | Purpose |
|---|---|---|---|
| GET | `/health` | Public | Liveness |
| POST | `/analysis` | Customer | Analyze JPG, PNG, or WebP image (max 8 MB) with Gemini |
| GET | `/analysis/history` | Customer | Own recent analysis results |
| POST | `/auth/register` | Public | Create customer (`name`, `email`, `password`) |
| POST | `/auth/login` | Public | Login (`email`, `password`); returns token and user |
| POST | `/auth/partner-setup` | Setup key | Create partner using `x-partner-setup-key` |
| GET | `/auth/me` | Any signed-in user | Current profile |
| POST | `/requests` | Customer | Submit `item` and `pickup` objects |
| GET | `/requests/mine` | Customer | Own requests, newest first |
| GET | `/requests/:id` | Owner or assigned partner | Request and status history |
| GET | `/partner/requests/eligible` | Partner | Unassigned submitted requests |
| GET | `/partner/requests/mine` | Partner | Requests assigned to caller |
| POST | `/partner/requests/:id/accept` | Partner | Atomically claim an unassigned request |
| PATCH | `/partner/requests/:id/status` | Assigned partner | Advance one permitted status (`status`, optional `note`) |

Example request body:

```json
{
  "item": { "category": "E-Waste", "name": "Old laptop", "condition": "Not working", "quantity": 1 },
  "pickup": { "address": "12 Green Street", "contactName": "Riya", "contactPhone": "+911234567890", "notes": "Call on arrival" }
}
```

Only the authenticated customer ID is stored as owner. The partner claim is a single conditional MongoDB update; no multi-document transaction is required. Duplicate/late claims return HTTP 409. Before acceptance, eligible partners see item and schedule information without the customer's address, contact details, or pickup notes; the assigned partner receives those details after claiming. Input schemas reject unknown fields and enforce lengths and formats. Login is rate-limited; security headers and configured CORS are enabled.

## Live demo sequence

1. Start MongoDB and the API, then confirm `/api/v1/health` responds.
2. Create a demo partner using the setup key and sign in separately as customer and partner.
3. Submit an e-waste request as customer; confirm it appears under the customer's request list.
4. Open the partner dashboard and accept that request.
5. Refresh the customer's list/details; verify `Accepted` and its timestamped history.
6. Advance to `Collected` as partner, refresh customer details, and verify the shared update.
7. Restart the Flutter app and load requests again to demonstrate server persistence.

## Current limits

Scan images are sent to the API for analysis but are not persisted. No recycler/courier notification or external processing-verification integration exists. `Completed` records a partner-reported processing update; it is not an independent recycler verification. Rewards and impact values are demo-only and do not represent verified processing or payouts. Profile edits and notification preferences are not persisted to the backend. API polling/refresh is used instead of realtime push. Device, Atlas, and physical-network checks must be reported only after they actually run.
