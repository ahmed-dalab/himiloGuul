# HimiloGuul Backend — Full Documentation

This document describes the **HimiloGuul** backend from project structure to the end: stack, configuration, models, routes, controllers, middlewares, and scripts.

---

## Table of Contents

1. [Overview](#1-overview)
2. [Project Structure](#2-project-structure)
3. [Tech Stack & Dependencies](#3-tech-stack--dependencies)
4. [Configuration & Environment](#4-configuration--environment)
5. [Entry Point & Server Setup](#5-entry-point--server-setup)
6. [Database](#6-database)
7. [Models (Mongoose Schemas)](#7-models-mongoose-schemas)
8. [Middleware](#8-middleware)
9. [Routes & API Summary](#9-routes--api-summary)
10. [Controllers (Business Logic)](#10-controllers-business-logic)
11. [Image Upload (Cloudinary)](#11-image-upload-cloudinary)
12. [Authentication & Authorization](#12-authentication--authorization)
13. [Scripts & Seeding](#13-scripts--seeding)
14. [Quick Reference](#14-quick-reference)

---

## 1. Overview

**HimiloGuul** is a **business marketplace** backend. It provides:

- **Auth**: Register and login (JWT).
- **Users**: Profiles, CRUD, roles (admin, seller, buyer).
- **Businesses**: Listings with categories, approval workflow, images, sold flag.
- **Contacts**: Buyer–seller inquiries linked to businesses.
- **Admin**: Dashboard, users, businesses, contacts, approve/reject, ban users.
- **RBAC**: Roles, permissions, menus, role–permission assignments (permission-based menu visibility).
- **Settings**: App-wide settings (app name, contact email, timezone).

The API is **REST-style**, uses **Express 5**, **MongoDB (Mongoose)**, and optional **Cloudinary** for images.

---

## 2. Project Structure

```
backend/
├── .gitignore
├── package.json
├── package-lock.json
├── README.md
├── BACKEND_DOCUMENTATION.md          # This file
├── ROLE_MENU_PERMISSION_FLOW.md      # RBAC design and API
├── TESTING_GUIDE.md                  # API testing examples
├── express_mongoose_cloudinary_docs.md
├── BUSINESS_PLAN_SUMMARY.md
├── himilo_guul_development_roadmap_and_tasks.md
├── tasks.md
├── src/
│   ├── server.js                     # Entry point: Express app, routes, DB connect
│   ├── config/
│   │   └── db.js                     # MongoDB connection
│   ├── models/                       # Mongoose schemas
│   │   ├── User.js
│   │   ├── Role.js
│   │   ├── Permission.js
│   │   ├── RolePermission.js
│   │   ├── Menu.js
│   │   ├── Business.js
│   │   ├── Contact.js
│   │   ├── Activity.js
│   │   └── Setting.js
│   ├── controllers/                  # Request handlers
│   │   ├── userController.js         # Auth (login, register), users CRUD, profile
│   │   ├── businessController.js    # Browse, my businesses, CRUD, approve, sold
│   │   ├── adminController.js       # Admin dashboard, businesses, users, contacts
│   │   ├── contactController.js
│   │   ├── menuController.js
│   │   ├── roleController.js
│   │   ├── permissionController.js
│   │   ├── rolePermissionController.js
│   │   ├── settingController.js
│   │   └── imageController.js        # Cloudinary upload/delete (used by business)
│   ├── routes/
│   │   ├── authRoutes.js
│   │   ├── userRoutes.js
│   │   ├── businessRoutes.js
│   │   ├── adminRoutes.js
│   │   ├── contactRoutes.js
│   │   ├── menuRoutes.js
│   │   ├── roleRoutes.js
│   │   ├── permissionRoutes.js
│   │   ├── rolePermissionRoutes.js
│   │   └── settingRoutes.js
│   ├── middlewares/
│   │   ├── authMiddleware.js         # protect, requirePermission, requireSelfOrPermission
│   │   └── uploadMiddleware.js       # Multer wrappers for single/multiple images
│   └── lib/
│       └── cloudinary.js             # Cloudinary v2 config
├── scripts/
│   ├── seed-roles.js                 # Roles + basic menus
│   ├── seed-menus.js
│   ├── seed-rbac.js                  # Full RBAC: roles, users, menus, permissions, role-permissions
│   ├── seed-activities.js
│   ├── seed-admin-and-home.js
│   ├── seed-seller-menus.js
│   └── test-api.js                  # API integration tests
└── Designs/                          # UI design assets (optional)
```

---

## 3. Tech Stack & Dependencies

| Package       | Purpose                          |
|---------------|----------------------------------|
| **express**   | Web framework (v5)              |
| **mongoose**  | MongoDB ODM                      |
| **dotenv**    | Environment variables            |
| **cors**      | Cross-origin requests            |
| **morgan**    | HTTP request logging             |
| **bcryptjs**  | Password hashing                 |
| **jsonwebtoken** | JWT for auth                 |
| **multer**    | Multipart form (file uploads)    |
| **cloudinary** | Image storage (optional)       |
| **nodemon**   | Dev server auto-restart          |

---

## 4. Configuration & Environment

Create a **`.env`** in the backend root:

| Variable                   | Required | Description                          |
|----------------------------|----------|--------------------------------------|
| `MONGO_URI`                | Yes      | MongoDB connection string            |
| `JWT_SECRET`               | Yes      | Secret for signing JWT               |
| `PORT`                     | No       | Server port (default `3001`)          |
| `CLOUDINARY_CLOUD_NAME`    | No*      | Cloudinary cloud name (for images)   |
| `CLOUDINARY_API_KEY`       | No*      | Cloudinary API key                   |
| `CLOUDINARY_API_SECRET`    | No*      | Cloudinary API secret                |

\* Required only if you use business image uploads (create/update business with images).

---

## 5. Entry Point & Server Setup

**File:** `src/server.js`

- Loads `dotenv`, connects to MongoDB via `config/db.js`.
- Creates Express app, uses **cors**, **express.json()**, and **morgan** (logs method, url, status, response time, body).
- Mounts all API routes under `/api/*` and exposes a **health** route.

**Mounted routes:**

| Mount path           | Route module           |
|----------------------|------------------------|
| `/api/auth`          | authRoutes             |
| `/api/users`         | userRoutes             |
| `/api/business`      | businessRoutes         |
| `/api/admin`         | adminRoutes            |
| `/api/roles`         | roleRoutes             |
| `/api/permissions`   | permissionRoutes       |
| `/api/role-permissions` | rolePermissionRoutes |
| `/api/menus`         | menuRoutes             |
| `/api/contacts`      | contactRoutes          |
| `/api/settings`      | settingRoutes          |

**Health check:** `GET /health` → `200` with message "Server is healthy".

---

## 6. Database

**File:** `src/config/db.js`

- Uses **mongoose** to connect to `process.env.MONGO_URI`.
- On failure: logs error and `process.exit(1)`.
- Exported as `connectDB` and called once from `server.js` at startup.

---

## 7. Models (Mongoose Schemas)

All models use **timestamps** (`createdAt`, `updatedAt`) unless noted.

### User (`src/models/User.js`)

- **Fields:** `name`, `email` (unique, validated), `password`, `roleId` (ref Role), `phone`, `location`, `profilePicture`, `isBanned` (default false).
- **Indexes:** `email`, `roleId`.
- **Methods:** `toJSON()` removes `password` from serialization.

### Role (`src/models/Role.js`)

- **Fields:** `name` (required, unique, trim).
- **Index:** `name`.

### Permission (`src/models/Permission.js`)

- **Fields:** `name` (required, unique), `menuId` (ref Menu, required).
- **Indexes:** `menuId`, `name`.
- Each permission belongs to **exactly one menu** (drives menu visibility for roles).

### RolePermission (`src/models/RolePermission.js`)

- **Fields:** `roleId` (ref Role), `permissionId` (ref Permission).
- **Unique compound index:** `(roleId, permissionId)`.
- **Indexes:** `roleId`, `permissionId`.
- Many-to-many: which permissions each role has.

### Menu (`src/models/Menu.js`)

- **Fields:** `name`, `path`, `parentId` (ref Menu, default null), `isActive` (default true), `icon`.
- **Indexes:** `parentId`, `path`.

### Business (`src/models/Business.js`)

- **Fields:** `name`, `address`, `phone`, `email` (unique, sparse), `website`, `owner` (ref User, required), `description`, `category` (enum: restaurant, retail, service, technology, healthcare, education, real-estate, hospitality, other), `askingPrice`, `annualRevenue`, `location`, `images` (array of `{ url, publicId }`), `status` (enum: pending, approved, rejected; default pending), `isSold` (default false).
- **Indexes:** category, location, askingPrice, status, owner, text index on name+description.

### Contact (`src/models/Contact.js`)

- **Fields:** `buyerRef`, `sellerRef`, `businessRef` (refs User, User, Business), `name`, `email`, `phone`, `message`, `status` (enum: pending, responded, closed; default pending).
- **Unique index:** `(buyerRef, sellerRef, businessRef)`.
- **Indexes:** buyerRef, sellerRef, businessRef, status.

### Activity (`src/models/Activity.js`)

- **Fields:** `type` (enum: user_registered, business_listed, deal_closed, user_updated, business_updated, business_approved, business_rejected, contact_created), `description`, `relatedId` (refPath), `relatedModel` (User | Business | Contact), `metadata` (Mixed).
- **Index:** `createdAt` descending (for recent activity).

### Setting (`src/models/Setting.js`)

- **Fields:** `appName` (default "HimiloGuul"), `contactEmail`, `timezone` (default "UTC").
- Used as a singleton for app-wide settings.

---

## 8. Middleware

### Auth (`src/middlewares/authMiddleware.js`)

- **`protect`**: Reads `Authorization: Bearer <token>`, verifies JWT with `JWT_SECRET`, loads user (with `roleId` populated as `name`), and loads the user’s **permission names** from the DB (RolePermission → Permission) into **`req.user.permissions`**. Sets `req.user`. Rejects if no token, invalid/expired token, user not found, or user banned.
- **`authorize(...roles)`**: After `protect`, allows only if `req.user.role` is in the given list (e.g. `authorize("admin", "seller")`). (Some routes may still use role-based checks, but the recommended approach is permission-based using `requirePermission`.)
- **`checkPermission(...permissionNames)`**: Allows only if the user’s role has at least one of the given permissions (uses `req.user.permissions` or DB).
- **`requireAdminOrPermission(...permissionNames)`**: Allows if user is **admin** **or** their role has any of the given permissions.
- **`requirePermission(...permissionNames)`**: Allows if `req.user.permissions` includes any of the given names.
- **`requireSelfOrPermission(permissionName, paramName)`**: Allows if the user is acting on themselves (e.g. `req.params.id === req.user._id`), otherwise requires the given permission.

### Upload (`src/middlewares/uploadMiddleware.js`)

- **`handleSingleUpload`**: Uses `imageController.uploadSingle` (Multer single file); responds with 400 on Multer errors (e.g. file size > 5MB) or other errors.
- **`handleMultipleUpload`**: Uses `imageController.uploadMultiple` (Multer array, max 10 files, 5MB each); same error handling.

Multer is configured in `imageController.js`: memory storage, image-only filter, 5MB limit.

---

## 9. Routes & API Summary

### Auth (`/api/auth`)

| Method | Path        | Auth  | Description      |
|--------|-------------|-------|------------------|
| POST   | /login      | No    | Login; returns token + user |
| POST   | /register   | No    | Register; body: name, email, password, role (role name) |

**Protected routes** use **`protect`** and **permission middleware** (e.g. `requirePermission("manage_users")`, `requireSelfOrPermission("manage_users")`). The middleware checks `req.user.permissions` (loaded by `protect` from RolePermission → Permission).

### Users (`/api/users`)

| Method | Path      | Auth                    | Required permission (in DB) | Description              |
|--------|-----------|--------------------------|-----------------------------|--------------------------|
| POST   | /         | protect, requirePermission      | manage_users        | Create user              |
| GET    | /profile  | protect, requirePermission      | view_profile        | Current user profile     |
| PUT    | /profile  | protect, requirePermission      | update_profile      | Update own profile       |
| GET    | /         | protect, requirePermission      | manage_users        | List users               |
| GET    | /:id      | No                       | —                            | Get user by ID (public)  |
| PUT    | /:id      | protect, requireSelfOrPermission | manage_users        | Update user (self or admin) |
| DELETE | /:id      | protect, requireSelfOrPermission | manage_users        | Delete user (self or admin) |

### Business (`/api/business`)

| Method | Path        | Auth                    | Required permission (in DB) | Description                    |
|--------|-------------|--------------------------|-----------------------------|--------------------------------|
| GET    | /           | No                       | —                            | Browse approved, unsold       |
| GET    | /my         | protect, requirePermission | view_seller_my_businesses | My businesses                  |
| GET    | /:id        | No*                      | —                            | By ID (public/owner logic in controller) |
| POST   | /           | protect, requirePermission, upload | create_business   | Create business               |
| PUT    | /:id        | protect, requirePermission, upload | update_business   | Update business               |
| DELETE | /:id        | protect, requirePermission | delete_business     | Delete business               |
| PUT    | /:id/approve| protect, requirePermission | manage_business_approval | Approve business        |
| PUT    | /:id/sold   | protect, requirePermission | mark_business_sold  | Mark as sold                  |

### Admin (`/api/admin`)

All require **protect** and permission checks (e.g. `requirePermission("view_admin_dashboard")`).

| Method | Path                    | Required permission (in DB) | Description                |
|--------|-------------------------|-----------------------------|----------------------------|
| GET    | /dashboard              | view_admin_dashboard        | Dashboard stats            |
| GET    | /activities             | view_admin_activities      | Recent activity            |
| GET    | /businesses             | view_admin_business         | List all businesses        |
| GET    | /businesses/pending     | view_admin_business         | List pending               |
| PUT    | /businesses/:id/approve | manage_business_approval   | Approve                    |
| PUT    | /businesses/:id/reject  | manage_business_approval   | Reject                     |
| GET    | /users                  | view_admin_users            | List all users             |
| PUT    | /users/:id/ban          | manage_users                | Ban/unban user             |
| DELETE | /users/:id              | manage_users                | Delete user                |
| GET    | /contacts               | manage_contacts             | List all contacts          |
| DELETE | /contacts/:id           | manage_contacts             | Delete contact             |

### Contacts (`/api/contacts`)

All require **protect** and permission checks.

| Method | Path  | Required permission (in DB) | Description           |
|--------|-------|-----------------------------|-----------------------|
| POST   | /     | create_contact              | Create contact        |
| GET    | /my   | view_my_contacts            | My contacts           |
| GET    | /:id  | view_contact                | Contact by ID         |
| PUT    | /:id  | update_contact              | Update contact        |
| DELETE | /:id  | delete_contact              | Delete contact        |

### Roles (`/api/roles`)

All require **protect** and `requirePermission("manage_roles")`.

| Method | Path  | Description   |
|--------|-------|---------------|
| POST   | /     | Create role   |
| GET    | /     | List roles    |
| GET    | /:id  | Get role      |
| PUT    | /:id  | Update role   |
| DELETE | /:id  | Delete role   |

### Permissions (`/api/permissions`)

All require **protect** and `requirePermission("manage_permissions")`.

| Method | Path  | Description      |
|--------|-------|------------------|
| POST   | /     | Create (body: name, menuId) |
| GET    | /     | List             |
| GET    | /:id  | Get one          |
| PUT    | /:id  | Update           |
| DELETE | /:id  | Delete           |

### Role-Permissions (`/api/role-permissions`)

All require **protect** and `requirePermission("manage_role_permissions")`.

| Method | Path                                      | Description                    |
|--------|-------------------------------------------|--------------------------------|
| POST   | /                                         | Assign (body: roleId, permissionId) |
| GET    | /                                         | List all                      |
| GET    | /role/:roleId                             | Permissions by role           |
| GET    | /permission/:permissionId                 | Roles by permission           |
| GET    | /:id                                     | Get one                       |
| PUT    | /:id                                     | Update                        |
| DELETE | /:id                                     | Delete by ID                  |
| DELETE | /role/:roleId/permission/:permissionId   | Unassign by role+permission   |

### Menus (`/api/menus`)

| Method | Path  | Auth                    | Required permission (in DB) | Description                          |
|--------|-------|--------------------------|-----------------------------|--------------------------------------|
| GET    | /     | No                       | —                            | List all (optional parentId query)   |
| GET    | /me   | protect, requirePermission | view_menus_me        | Menus for current user               |
| GET    | /:id  | No                       | —                            | Get menu by ID                       |
| POST   | /     | protect, requirePermission | manage_menus         | Create menu                          |
| PUT    | /:id  | protect, requirePermission | manage_menus         | Update menu                          |
| DELETE | /:id  | protect, requirePermission | manage_menus         | Delete menu                          |

### Settings (`/api/settings`)

| Method | Path | Auth                    | Required permission (in DB) | Description   |
|--------|------|--------------------------|-----------------------------|----------------|
| GET    | /    | protect, requirePermission | manage_settings     | Get settings  |
| PUT    | /    | protect, requirePermission | manage_settings     | Update settings |

---

## 10. Controllers (Business Logic)

- **userController**: Register (with role by name), login (JWT + user), profile get/update, createUser (admin), getAllUsers (filters, pagination), getUserById, updateUser (self/admin, role resolution), deleteUser (self/admin, blocks if user has businesses).
- **businessController**: browseBusinesses (approved, unsold, filters, pagination), getMyBusinesses, getBusinessById (visibility by status and role), createBusiness (owner from admin or self, images via imageController), updateBusiness (owner/admin, optional new images), deleteBusiness (plus Cloudinary cleanup), markBusinessAsSold, approveBusiness.
- **adminController**: listAllBusinesses, listPendingBusinesses, approve/reject business, listAllUsers, banUnbanUser, deleteUser, listAllContacts, deleteContact, getDashboardStats, getRecentActivity.
- **contactController**: createContact, getMyContacts, getContactById, updateContact, deleteContact (all with buyer/seller/admin authorize).
- **menuController**: getAllMenus, getMenusForMe (permission-based menus for current user), getMenuById, createMenu, updateMenu, deleteMenu.
- **roleController**, **permissionController**, **rolePermissionController**, **settingController**: Standard CRUD and helpers (e.g. getPermissionsByRole, getRolesByPermission).
- **imageController**: Multer config (memory, image filter, 5MB), uploadSingle/uploadMultiple, uploadImage/uploadImages (Cloudinary stream), deleteImage/deleteImages. Used by business create/update and delete.

---

## 11. Image Upload (Cloudinary)

- **Config:** `src/lib/cloudinary.js` — Cloudinary v2 configured with env vars.
- **Upload:** In `imageController.js`, Multer stores files in memory; images are uploaded to Cloudinary in folder `himilo-guul`, returning `{ url, publicId }`. Business create/update use `uploadImages(req.files)`; business delete calls `deleteImages(publicIds)` for stored images.
- **Limits:** 5MB per file; max 10 files for business images. Enforced in upload middleware with clear error messages.

---

## 12. Authentication & Authorization

- **Login:** POST `/api/auth/login` with `email`, `password` → bcrypt compare → JWT signed with `id`, expiry 1d → returns `token` and `user` (password stripped).
- **Register:** POST `/api/auth/register` with `name`, `email`, `password`, `role` (role **name**) → role resolved to Role document → user created with `roleId` → JWT and user returned.
- **Protected routes:** Send header `Authorization: Bearer <token>`. `protect` sets `req.user` and loads **`req.user.permissions`** (permission names for the user’s role from RolePermission + Permission). Banned users get 403.
- **Permission checks:** Protected API routes use middleware like `requirePermission(...)` and `requireSelfOrPermission(...)` to check whether `req.user.permissions` contains a required permission name (RolePermission → Permission).

---

## 13. Scripts & Seeding

- **`npm run dev`** — Start server with nodemon (`src/server.js`).
- **`npm run seed:roles`** — `node scripts/seed-roles.js`: creates roles (admin, seller, buyer) and basic menus (bottom nav + drawer).
- **`npm run seed:rbac`** — `node scripts/seed-rbac.js`: full RBAC — roles, admin/seller/buyer users, menus, permissions (with menuId), role-permissions (seller/buyer/admin permission sets). Default credentials: ali@gmail.com/admin123, seller@example.com/seller123, buyer@example.com/buyer123.
- **`npm run test:api`** — `node scripts/test-api.js`: runs API tests (server must be running).

Other scripts (run with `node scripts/<name>.js`):

- **seed-menus.js** — Menus only.
- **seed-activities.js**, **seed-admin-and-home.js**, **seed-seller-menus.js** — Additional seed data as needed.

---

## 14. Quick Reference

| What you need           | Where / How                                      |
|-------------------------|--------------------------------------------------|
| Start server            | `npm run dev` (port 3001 by default)            |
| Health check            | `GET /health`                                   |
| Auth                    | `POST /api/auth/login`, `POST /api/auth/register` |
| Token                   | `Authorization: Bearer <token>`                 |
| Roles                   | admin, seller, buyer (seed or create via API)   |
| Route permissions       | Enforced in code using middleware like `requirePermission(...)` (permission names are stored in DB; the route specifies which permission(s) are required). |
| Permissions & menus     | See **ROLE_MENU_PERMISSION_FLOW.md**            |
| Business images         | Optional; set CLOUDINARY_* in .env               |
| First-time setup        | Set MONGO_URI, JWT_SECRET; run `npm run seed:rbac` |

For request/response examples and Postman/cURL, see **TESTING_GUIDE.md**.
