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

The Flutter build reads `API_BASE_URL` with `--dart-define`. The default is `http://10.0.2.2:3000/api/v1`, which reaches the development computer from the standard Android emulator only. For a physical phone, find the Windows PC's active Wi-Fi/Ethernet IPv4 address with `Get-NetIPAddress -AddressFamily IPv4` and build with `flutter run --dart-define=API_BASE_URL=http://<PC-LAN-IPv4>:3000/api/v1`. Replace the placeholder with the actual address (do not type the angle brackets). Both devices must share a network, and Windows Firewall must permit inbound TCP port 3000 on the private network. Do not disable the firewall globally, use a public tunnel, or use the emulator address on a phone. The backend listens on all local interfaces after its MongoDB connection succeeds. Use HTTPS for a hosted demo.

Example: `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1`. Local HTTP is enabled for Android development through the app's development network configuration; production deployments should serve HTTPS. The app stores its bearer token in platform secure storage and refreshes request data from the API.

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
