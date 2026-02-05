# HimiloGuul – App Guide & Manual Testing

This document explains how the app works and how to manually test it from the Flutter app as **Admin** and **Seller**.

---

## 1. How the app works

### 1.1 Overview

- **HimiloGuul** is a business marketplace app with:
  - **Buyers** – browse and view businesses (no login required to browse).
  - **Sellers** – manage their own businesses, contacts, and profile (seller portal).
  - **Admins** – manage users, roles, permissions, menus, businesses, and settings (admin portal).

- After login, the user is redirected by **role**:
  - **Admin** → `/admin` (Admin layout: bottom nav + drawer).
  - **Seller** → `/seller` (Seller layout: bottom nav + drawer).
  - **Buyer** (or no role) → browse business screen.

### 1.2 Role-Based Access Control (RBAC)

- Each user has **one role** (admin, seller, or buyer).
- **Roles** have **permissions** (assigned via Role Permissions in admin).
- **Menus** are not assigned to users or roles directly. Each **permission** has exactly one **menu** (Permission.menuId).
- **RolePermission** links a role to permissions. A user **sees a menu** only if their role has at least one permission whose menu is that menu.
- Menus the user does not have permission for are **hidden** (not disabled).
- Backend APIs still enforce permission checks regardless of what menus are shown.

### 1.3 Menus by role (after running RBAC seed)

| Role   | Menus shown (permission-driven) |
|--------|----------------------------------|
| Seller | Home, My Business, Contacts, Profile (paths under `/seller/`) |
| Admin  | Home, Business, Users, Profile (bottom nav) + Roles, Permissions, Role Permissions, Menus, Settings (drawer) – paths under `/admin` |

- **Seller** sees only seller-path menus because their role has permissions like `view_seller_dashboard`, `view_seller_my_businesses`, `view_seller_contacts`, `view_seller_profile`.
- **Admin** sees admin-path menus because their role has all view_admin_* and manage_* permissions.

### 1.4 Main flows

- **Login** → Backend returns user + token; frontend stores token and user (including role). Frontend calls **GET /api/menus/me** to load permission-based menus, then redirects to `/admin` or `/seller` by role.
- **Admin portal** – Bottom nav: Home (dashboard), Business, Users, Profile. Drawer: Roles, Permissions, Role Permissions, Menus, Settings. Tapping a drawer item navigates to that screen (e.g. Role Permissions).
- **Seller portal** – Bottom nav: Home, My Business, Contacts, Profile. Drawer: any extra seller menus (if any). Body content switches by selected menu (dashboard, my businesses, contacts, profile).

---

## 2. Prerequisites for manual testing

### 2.1 Backend

1. **Node.js** and **MongoDB** installed and running.
2. In `backend/`:
   - Copy `.env.example` to `.env` (if needed) and set `MONGO_URI` and `JWT_SECRET`.
   - Install dependencies: `npm install`
   - Start server: `npm start` (default port 3000).
3. **Seed RBAC data** (creates roles, menus, permissions with menuId, role–permission assignments, and admin/seller users):
   ```bash
   cd backend
   node scripts/seed-rbac.js
   ```
   This creates:
   - **Admin user:** `ali@gmail.com` / `admin123`
   - **Seller test user:** `seller@example.com` / `seller123` (for manual testing)
   - **Seller role** with view permissions; **admin role** with all permissions.

### 2.2 Flutter app

1. In `frontend/`:
   - Install dependencies: `flutter pub get`
   - Configure API base URL in `lib/core/constants/api_constants.dart`:
     - Android Emulator: `http://10.0.2.2:3000/api`
     - iOS Simulator / real device (same machine as backend): `http://localhost:3000/api` or your machine IP.
2. Run the app: `flutter run` (choose device/emulator).

### 2.3 Seller test user

After running `node scripts/seed-rbac.js`, you can log in as seller with:

- **Email:** `seller@example.com`
- **Password:** `seller123`

Alternatively, you can create another seller user via **Admin → Users** (add user, assign role **Seller**) and use that account to test.

---

## 3. Manual testing – Admin user

### 3.1 Login as admin

1. Open the app → you should see the **Welcome** (or Login) screen.
2. Go to **Login**.
3. Enter:
   - Email: `ali@gmail.com`
   - Password: `admin123`
4. Tap **Login**.
5. **Expected:** You are redirected to the **Admin** layout (`/admin`). You see:
   - App bar: “HimiloGuul” and logout.
   - **Bottom nav:** Home, Business, Users, Profile.
   - **Drawer:** Open menu (☰) → Roles, Permissions, Role Permissions, Menus, Settings (and any other admin menus returned by `/menus/me`).

### 3.2 Admin – Bottom nav

1. **Home** – Dashboard screen (overview).
2. **Business** – List of businesses (admin view).
3. **Users** – List of users; you can add/edit users and assign roles.
4. **Profile** – Admin profile screen.

Tap each tab and confirm the correct screen loads.

### 3.3 Admin – Drawer (management screens)

1. Open the **drawer** (hamburger icon).
2. Tap **Roles** – **Expected:** Roles management screen; list of roles (e.g. admin, seller).
3. Tap **Menus** – **Expected:** Menus management screen; list of menus.
4. Tap **Permissions** – **Expected:** Permissions management screen; list of permissions.
5. Tap **Role Permissions** – **Expected:** Role Permissions screen; list of role–permission assignments; you can assign a permission to a role or remove an assignment.
6. Tap **Settings** – **Expected:** Settings screen.

Confirm that each drawer item navigates to the correct screen and that data loads (if applicable).

### 3.4 Admin – Create seller user (for seller testing)

1. Go to **Users** (bottom nav or drawer).
2. Tap **+** (or “Add user”).
3. Create a user, e.g.:
   - Name: Test Seller  
   - Email: seller@example.com  
   - Password: seller123  
   - Role: **Seller**
4. Save.
5. **Expected:** User appears in the list with role Seller. You will use this account to test the seller portal (log out and log in as seller@example.com / seller123).

### 3.5 Admin – Menu visibility (permission-based)

1. In **Role Permissions**, remove one or more permissions from the **admin** role (e.g. remove “Menus” permission).
2. Log out and log in again as admin.
3. **Expected:** The menu(s) linked to the removed permission are **hidden** (e.g. “Menus” no longer appears in the drawer). APIs for that feature should still enforce permission checks if called directly.
4. Restore the permission via Role Permissions and log in again to confirm the menu reappears.

### 3.6 Logout (admin)

1. Tap **Logout** in the app bar.
2. **Expected:** You are taken back to the Welcome/Login screen; session cleared.

---

## 4. Manual testing – Seller user

### 4.1 Login as seller

1. On the Login screen, enter the seller test credentials:
   - **Email:** `seller@example.com`
   - **Password:** `seller123`
2. Tap **Login**.
4. **Expected:** You are redirected to the **Seller** layout (`/seller`). You see:
   - App bar: “HimiloGuul” and logout.
   - **Bottom nav:** Home, My Business, Contacts, Profile (only seller-path menus; no admin menus).
   - **Drawer:** Open menu (☰) – may show only header if all seller menus are in bottom nav.

### 4.2 Seller – Bottom nav

1. **Home** – Seller dashboard (overview).
2. **My Business** – Placeholder/screen for “My Businesses”.
3. **Contacts** – Placeholder/screen for “Contacts”.
4. **Profile** – Seller profile screen.

Tap each tab and confirm the correct screen loads and no admin-only content is visible.

### 4.3 Seller – No admin menus

1. Open the **drawer**.
2. **Expected:** No “Users”, “Roles”, “Permissions”, “Role Permissions”, “Menus”, or “Settings” (these are admin-path menus and require admin permissions). Seller only sees menus they have permission for (view_seller_dashboard, view_seller_my_businesses, view_seller_contacts, view_seller_profile).

### 4.4 Seller – Logout

1. Tap **Logout** in the app bar.
2. **Expected:** Return to Welcome/Login screen; session cleared.

---

## 5. Quick reference

| Item            | Admin                    | Seller                          |
|----------------|--------------------------|----------------------------------|
| Login          | `ali@gmail.com` / `admin123` | `seller@example.com` / `seller123` (after seed-rbac.js) |
| Layout         | `/admin`                 | `/seller`                        |
| Bottom nav     | Home, Business, Users, Profile | Home, My Business, Contacts, Profile |
| Drawer         | Roles, Permissions, Role Permissions, Menus, Settings | Only seller-permitted menus (if any beyond bottom nav) |
| Menu source    | `GET /api/menus/me` → filter by path `/admin` | `GET /api/menus/me` → filter by path `/seller` |

---

## 6. Troubleshooting

- **Menus empty after login**  
  - Ensure backend is running and `GET /api/menus/me` is called with a valid token.  
  - Ensure RBAC seed was run (`node scripts/seed-rbac.js`) so the user’s role has permissions and MenuPermission links exist.

- **Admin sees no management menus**  
  - Run `seed-rbac.js` so the admin role has all view_admin_* and manage_* permissions (each permission has a menuId).

- **Seller sees admin menus**  
  - Seller role should only have view_seller_* permissions; admin has view_admin_* and manage_*. Check Role Permissions; ensure frontend filters menus by path prefix (`/seller` for seller layout).

- **“Network error” or no response**  
  - Confirm backend URL in `api_constants.dart` (e.g. `10.0.2.2` for Android emulator, correct IP for device).  
  - Ensure backend is running on the expected port (e.g. 3000).

- **Cannot log in as seller**  
  - Run `node scripts/seed-rbac.js` to create the seller test user (`seller@example.com` / `seller123`). Or create a user with role **Seller** from Admin → Users and use that account.
