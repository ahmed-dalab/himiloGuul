# HimiloGuul — Development Roadmap (Section-by-section, Step-by-step)

This document is a detailed, practical guide for your 4-person team to build the HimiloGuul MVP. It focuses on the exact order to develop features, how to split work across team members, specific backend + Flutter UI tasks, and all technical details needed to implement the authentication feature first and then continue through the product.

---

## Table of Contents
1. Objectives & Principles
2. High-level Development Order (section-by-section)
3. Sprint 1 (Auth backend → Flutter login/register) — full technical guide
4. What comes next (after Auth): Step-by-step feature order
5. Tasks breakdown for 4 team members (clear, independent tasks)
6. API & Data model references (auth-focused + overall mapping)
7. Testing & QA checklist (for each section)
8. CI / Deployment / Security / Monitoring checklist
9. Merge review & collaboration rules
10. Appendix: Example requests/responses, token handling, error codes

---

## 1. Objectives & Principles
- Build **incrementally**: finish a vertical slice (backend + frontend) for authentication before moving to the next vertical slice.
- Keep interfaces stable: design API contracts first so the Flutter team can work in parallel.
- Clear ownership: assign clear tasks for each member with no blocking dependencies where possible.
- Secure defaults: authentication and authorization must be correct from day one.
- Automate basic checks: linting, unit tests for critical pieces (auth flows), and simple end-to-end checks.

---

## 2. High-level Development Order (section-by-section)
1. Authentication & User Profiles (backend) + Flutter Login/Register screens. ✅ *Start here*.
2. Business model + CRUD (seller): create listing endpoints, image upload integration (Cloudinary), and seller UI pages.
3. Business browsing (buyer): public listing feeds, filters, detail pages, and buyer UI.
4. Conversations & Messages: simple conversation flow, message posting endpoints, and conversation UI.
5. Admin dashboard endpoints & UI: pending listings, approve/reject, user banning, monitoring.
6. Polish: search, pagination, file validations, rate-limiting, analytics.
7. Hardening & deployment: HTTPS, environment handling, backups, monitoring.

---

## 3. Sprint 1 — Authentication Backend → Flutter Login & Register
This sprint is the highest priority. Deliverables: secure auth backend, tokens and refresh handling, basic user profile endpoints, and Flutter login/register screens integrated with the backend.

### 3.1 Backend: Auth Implementation (Express + Mongoose)
**Files & Structure (suggested)**
```
backend/
├─ src/
│  ├─ controllers/
│  │  └─ auth.controller.js
│  ├─ models/
│  │  └─ user.model.js
│  ├─ routes/
│  │  └─ auth.routes.js
│  ├─ middlewares/
│  │  ├─ auth.middleware.js
│  │  └─ validate.middleware.js
│  ├─ utils/
│  │  └─ jwt.util.js
│  ├─ app.js
│  └─ server.js
```

**User model (Mongoose)**
```js
// src/models/user.model.js
import mongoose from 'mongoose';

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true, lowercase: true },
  password: { type: String, required: true },
  role: { type: String, enum: ['buyer','seller','admin'], default: 'buyer' },
  phone: { type: String },
  location: { type: String },
  isBanned: { type: Boolean, default: false }
}, { timestamps: true });

userSchema.methods.toJSON = function () {
  const obj = this.toObject();
  delete obj.password;
  return obj;
};

export default mongoose.model('User', userSchema);
```

**Auth flow & utilities**
- Use **bcrypt** for password hashing.
- Use **jsonwebtoken** for access tokens.
- Use a short-lived access token and optional refresh token if desired (start with access-only for MVP, but add refresh token if you want persistent sessions).

**JWT Utility example**
```js
// src/utils/jwt.util.js
import jwt from 'jsonwebtoken';

export const signAccessToken = (payload) =>
  jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '1d' });

export const verifyToken = (token) => jwt.verify(token, process.env.JWT_SECRET);
```

**Auth controller**
```js
// src/controllers/auth.controller.js
import User from '../models/user.model.js';
import bcrypt from 'bcryptjs';
import { signAccessToken } from '../utils/jwt.util.js';

export const register = async (req, res) => {
  const { name, email, password, role } = req.body;
  const existing = await User.findOne({ email });
  if (existing) return res.status(409).json({ message: 'Email already exists' });

  const hashed = await bcrypt.hash(password, 10);
  const user = await User.create({ name, email, password: hashed, role });

  const token = signAccessToken({ id: user._id, role: user.role });
  res.status(201).json({ user: user.toJSON(), token });
};

export const login = async (req, res) => {
  const { email, password } = req.body;
  const user = await User.findOne({ email });
  if (!user) return res.status(401).json({ message: 'Invalid credentials' });

  const ok = await bcrypt.compare(password, user.password);
  if (!ok) return res.status(401).json({ message: 'Invalid credentials' });

  if (user.isBanned) return res.status(403).json({ message: 'User banned' });

  const token = signAccessToken({ id: user._id, role: user.role });
  res.json({ user: user.toJSON(), token });
};
```

**Auth routes**
```js
// src/routes/auth.routes.js
import express from 'express';
import { register, login } from '../controllers/auth.controller.js';

const router = express.Router();
router.post('/register', register);
router.post('/login', login);

export default router;
```

**Auth middleware (protect & role check)**
```js
// src/middlewares/auth.middleware.js
import jwt from 'jsonwebtoken';
import User from '../models/user.model.js';

export const protect = async (req, res, next) => {
  const header = req.headers.authorization;
  if (!header) return res.status(401).json({ message: 'No token' });

  const token = header.split(' ')[1];
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(decoded.id);
    if (!user) return res.status(401).json({ message: 'Invalid token' });
    if (user.isBanned) return res.status(403).json({ message: 'User banned' });
    req.user = user;
    next();
  } catch (err) {
    return res.status(401).json({ message: 'Invalid token' });
  }
};

export const authorize = (roles = []) => (req, res, next) => {
  if (!roles.includes(req.user.role)) return res.status(403).json({ message: 'Forbidden' });
  next();
};
```

**Validation**
- Validate incoming payloads using a schema validator (Yup, Joi, or express-validator). Implement a validate middleware to reject bad requests with clear errors.

**Environment & secrets**
- Keep `JWT_SECRET`, `MONGO_URI`, and other secrets in environment variables.

**Recommended response shape**
```json
{ "user": { "_id":"...","name":"...","email":"...","role":"buyer" }, "token":"..." }
```

### 3.2 Backend: User profile endpoints (for Sprint 1)
**Routes**
- `GET /users/me` → return current user (protected)
- `PATCH /users/me` → update name, phone, location (protected)

**Controller snippets**
```js
export const getMe = (req, res) => res.json({ user: req.user.toJSON() });

export const updateMe = async (req, res) => {
  const updates = ['name','phone','location'];
  updates.forEach(k => { if (req.body[k] !== undefined) req.user[k] = req.body[k]; });
  await req.user.save();
  res.json({ user: req.user.toJSON() });
};
```

### 3.3 Backend: Extra niceties to add now
- Rate limit `POST /auth/login` to prevent brute force.
- Strong password policy check on register (e.g., min length).
- Email uniqueness enforced at DB level and handled gracefully.
- Logging for auth events (success/failure).

### 3.4 Flutter: Login & Register screens (connect to backend)
**Flutter structure (suggested)**
```
flutter_app/
├─ lib/
│  ├─ screens/
│  │  ├─ auth/
│  │  │  ├─ login_page.dart
│  │  │  └─ register_page.dart
│  ├─ services/
│  │  └─ api_service.dart
│  ├─ models/
│  │  └─ user.dart
│  └─ main.dart
```

**Networking**
- Use `http` or `dio` package.
- Store tokens securely using `flutter_secure_storage` (preferred) or `shared_preferences` for MVP.

**API calls (example with `dio`)**
```dart
// api_service.dart
import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://api.yourdomain.com'));

  Future<Map> login(String email, String password) async {
    final r = await _dio.post('/auth/login', data: { 'email': email, 'password': password });
    return r.data;
  }

  Future<Map> register(String name, String email, String password, String role) async {
    final r = await _dio.post('/auth/register', data: { 'name': name, 'email': email, 'password': password, 'role': role });
    return r.data;
  }
}
```

**Login flow in Flutter**
1. User submits email & password on login screen.
2. App calls `POST /auth/login`.
3. On success, store token securely and navigate to the protected area.
4. Attach `Authorization: Bearer <token>` to subsequent requests.

**Register flow in Flutter**
1. User fills fields and chooses role (buyer or seller).
2. App calls `POST /auth/register`.
3. On success, store token and navigate to onboarding or create-listing flow for sellers.

**Token storage suggestion**
- Use `flutter_secure_storage` to store the JWT.
- Create an `AuthProvider` or `AuthService` to provide current user and token to the app.

**Error handling**
- Show friendly messages for HTTP 4xx and 5xx.
- On 401 or token expiry, clear stored token and return to login.

---

## 4. What comes next — Step-by-step feature order after Auth
After auth + profile are working end-to-end, proceed in the following vertical slices. Build each slice backend → mock UI → real UI.

1. **Business registration (seller)**
   - Backend: `POST /businesses`, image handling (Cloudinary), model and `GET /businesses/my`, `PATCH`, `DELETE`.
   - UI: Seller "Create Listing" form, image picker upload flow (upload to backend which forwards to Cloudinary or direct signed upload).
2. **Business browsing (buyer)**
   - Backend: `GET /businesses` with filters and pagination, `GET /businesses/:id`.
   - UI: Listing feed, filters, detail page.
3. **Conversations & messaging**
   - Backend: `POST /conversations`, `POST /messages`, retrieval endpoints. (Messages stored in DB.)
   - UI: Conversation list, message thread view, send message feature.
4. **Admin panel features**
   - Backend: admin endpoints for pending businesses, users, conversations.
   - UI: Simple web admin or Flutter admin screens.
5. **Polish & non-functional concerns**
   - Rate-limits, validation, file size checks, input sanitization, logging, monitoring.

---

## 5. Tasks breakdown for 4 team members
Assign the following roles so every member has clear responsibilities that can run largely in parallel.

**Member A — Backend Lead (Auth + Core APIs)**
- Implement auth (routes, controllers, models).
- Implement user profile endpoints.
- Implement JWT & protect middleware.
- Add request validation and rate-limiting for auth endpoints.
- Write unit tests for auth logic.

**Member B — Backend (Business & Conversations)**
- Implement Business model, create/list/update/delete endpoints.
- Integrate Cloudinary for images (upload handler + store publicId/url on Business document).
- Implement Conversation & Message models and endpoints.
- Implement Admin endpoints (pending, approve/reject) with role-based middleware.

**Member C — Flutter (Auth + onboarding for seller)**
- Implement Login & Register screens with validation.
- Implement secure token storage & Auth provider.
- Implement onboarding flow: for sellers, quick flow to create a first listing or go to seller dashboard.
- Implement basic error UI and loading states.

**Member D — Flutter (Buyer & Conversations) + QA**
- Implement business browsing UI: listing feed, filters, details page.
- Implement conversation UI: start conversation, send/read messages.
- Write manual QA checklist and run cross-device tests.
- Help with integration testing and reproduce backend bugs.

**Collaboration notes**
- While Member A implements backend auth, Members C & D can build and test UI against mock API responses or a local dev backend.
- Member B's Cloudinary integration requires credentials; create a shared test Cloudinary account for dev.
- Use feature branches and PRs. Each PR should include at least one reviewer.

---

## 6. API & Data model references (auth-focused + overall mapping)
**Auth Endpoints**
- `POST /auth/register` → body: `{ name, email, password, role }` → returns `{ user, token }`
- `POST /auth/login` → body: `{ email, password }` → returns `{ user, token }`

**User endpoints**
- `GET /users/me` → headers: `Authorization: Bearer <token>`
- `PATCH /users/me` → body: `{ name?, phone?, location? }`

**Business endpoints (reference)**
- `POST /businesses` (seller only) → create listing (images upload URLs)
- `GET /businesses` → public list with query: `?category=&minPrice=&maxPrice=&location=&page=&limit=`
- `GET /businesses/:id`
- `GET /businesses/my` (seller only)
- `PATCH /businesses/:id` (seller only, if not approved)
- `DELETE /businesses/:id` (seller only)
- `PATCH /admin/businesses/:id/approve` (admin only)
- `PATCH /admin/businesses/:id/reject` (admin only)

**Conversations & Messages**
- `POST /conversations` → `{ businessId }` (creates conversation)
- `GET /conversations/my`
- `GET /conversations/:id`
- `POST /messages` → `{ conversationId, text }`
- `GET /messages/:conversationId`

**Models (summary)**
- User: name, email, password, role, phone, location, isBanned
- Business: owner (userRef), name, category, askingPrice, description, location, contactDetails, images[{url, publicId}], status, isSold
- Conversation: buyerRef, sellerRef, businessRef, createdAt
- Message: conversationRef, senderRef, text, createdAt

---

## 7. Testing & QA Checklist (for Auth sprint and beyond)
**Auth-specific**
- Register: cannot register with existing email → 409
- Login: wrong credentials → 401
- Protected routes without token → 401
- Token tampering / invalid token → 401
- Banned user cannot login / access → 403
- Password stored hashed (verify DB)

**General**
- Endpoint input validation returns helpful error messages.
- Cloudinary images rejected if wrong type / too large.
- Pagination works and guards against huge `limit` values.
- Role-based routes reject unauthorized roles.

**Automated tests**
- Add unit tests for password hashing, token signing/verification.
- Add integration tests for register/login → getMe flows.

---

## 8. CI / Deployment / Security / Monitoring checklist
**CI**
- Run `eslint`, `prettier` on PRs.
- Run unit tests for backend on PRs.

**Security**
- Ensure HTTPS in production.
- Use secure storage for tokens (mobile) and secrets (backend).
- Use helmet and express-rate-limit on backend.

**Deployment**
- Use environment variables for MONGO_URI, JWT_SECRET, CLOUDINARY_* keys.
- Deploy backend to a provider that supports Node.js (e.g., Heroku, Render, Fly, DigitalOcean App Platform). For production DB use managed MongoDB (Atlas) or hosted alternative.

**Monitoring**
- Add simple request logging (morgan) and an error-tracking tool (Sentry) if possible.
- Export basic metrics: successful logins, failed logins, new listings created, approvals.

---

## 9. Merge review & collaboration rules
- Create a branch per feature: `feature/auth-register`, `feature/business-crud`, etc.
- Each PR must:
  - Have a descriptive title & short summary.
  - Include at least one reviewer.
  - Pass CI checks before merging.
  - Include API contract changes in a single `api.md` file.
- Keep commits small and focused.

---

## 10. Appendix: Example requests/responses & Error codes
**Register — Request**
```
POST /auth/register
Content-Type: application/json
{
  "name": "Hassan",
  "email": "hassan@example.com",
  "password": "StrongPassword123",
  "role": "seller"
}
```
**Register — Success Response**
```
201 Created
{
  "user": { "_id": "...", "name": "Hassan", "email": "hassan@example.com", "role": "seller" },
  "token": "<jwt>"
}
```

**Login — Request**
```
POST /auth/login
{ "email":"hassan@example.com", "password":"StrongPassword123" }
```
**Login — Error (wrong password)**
```
401 Unauthorized
{ "message": "Invalid credentials" }
```

**Common error codes**
- `400` Bad Request — invalid input
- `401` Unauthorized — missing/invalid token or credentials
- `403` Forbidden — banned user or insufficient role
- `404` Not Found — resource not found
- `409` Conflict — duplicate resources (e.g., email)
- `500` Internal Server Error — unexpected

---

## Final notes & next action
1. **Start now with Sprint 1**: Backend Lead (Member A) creates the auth endpoints and provides a running dev backend URL or Postman collection. Flutter members (C & D) start building UI screens and test against the dev backend or mocks.
2. **Daily check-ins**: keep updates short and sync blockers early.
3. **Keep API contracts in `api.md`** so the frontend and backend remain decoupled and can work in parallel.

If you want, I can now:
- Generate `api.md` from this document (Swagger-style),
- Create a recommended GitHub project board with tasks per member,
- Or produce sample Postman collections / curl commands for quick testing.

Tell me which of these you'd like next and I will create it as an MD file.

