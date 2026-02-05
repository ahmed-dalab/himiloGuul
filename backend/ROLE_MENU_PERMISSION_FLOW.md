# RBAC: Role-Based Access Control – Models and Flow

This document describes the data model, setup flow, and API for roles, users, menus, permissions, and role–permission assignments.

---

## 1. Models and relationships

| Table            | Purpose | Key fields |
|------------------|---------|------------|
| **Role**         | Roles such as admin, seller, buyer (and any you create). | `name` (unique) |
| **User**         | Users; each user is assigned to **one role**. | `name`, `email`, `password`, **`roleId`** (→ Role) |
| **Menu**         | Menu items (e.g. Admin Home, Users, Seller Dashboard). | `name`, `path`, `parentId`, `isActive`, `icon` |
| **Permission**   | Permissions; **each permission relates to one menu**. | `name` (unique), **`menuId`** (→ Menu, required) |
| **RolePermission** | Many-to-many: which permissions each role has. | **`roleId`** (→ Role), **`permissionId`** (→ Permission) |

- **User** → **Role**: one-to-one (user has one `roleId`).
- **Permission** → **Menu**: one-to-one (permission has one `menuId`).
- **Role** ↔ **Permission**: many-to-many via **RolePermission** (`roleId`, `permissionId`).

**Menu visibility:** A user sees a menu if their role has at least one permission whose `menuId` is that menu. Backend APIs also enforce permission checks by name (e.g. `manage_users`).

---

## 2. Setup flow (order of operations)

Use this order when configuring the system:

1. **Create roles**  
   Create the roles you need (e.g. admin, seller, buyer).  
   → **Role** table.

2. **Create users and assign a role**  
   Create a user; when creating (or editing) the user, assign them to an **existing role**.  
   → **User** table with `roleId` set.

3. **Create menus**  
   Create all menu items (name, path, optional parent).  
   → **Menu** table.

4. **Create permissions and link each to a menu**  
   Create permissions; for **each permission** set its **menu** (required). Each permission relates to exactly one menu; multiple permissions can point to the same menu.  
   → **Permission** table with `menuId` set.

5. **Assign permissions to roles**  
   For each role, assign the permissions that role should have (e.g. Admin gets all, Seller gets view_seller_*).  
   → **RolePermission** table (`roleId`, `permissionId`).

After this, when a user logs in, the app loads their role and that role’s permissions, then shows only the menus that those permissions point to (via `menuId`).

### Flow at a glance

```
1. Roles          →  Create admin, seller, buyer (and others)
2. Users          →  Create user, assign to an existing role (roleId)
3. Menus          →  Create menu items (name, path, …)
4. Permissions    →  Create permission, set its menu (menuId)
5. RolePermission →  Assign each permission to one or more roles (roleId + permissionId)
```

**Result:** User (roleId) → Role → RolePermission → Permission (menuId) → Menu. The user sees only menus that at least one of their role’s permissions points to.

---

## 3. Design summary

- **Permission** has a required **menuId**: each permission belongs to **exactly one menu**. No separate menu–permission link table.
- **RolePermission** is the many-to-many table between **Role** and **Permission**: it stores which permissions each role has.
- **User** has **roleId**: each user has one role. When creating a user, you assign one of the existing roles.

---

## Backend status: **implemented**

### 1. Role

| Action   | Method | Endpoint        | Auth   | Body   |
|----------|--------|-----------------|--------|--------|
| Create   | POST   | `/api/roles`    | admin  | `{ name }` |
| List     | GET    | `/api/roles`    | admin  | -      |
| Get one  | GET    | `/api/roles/:id`| admin  | -      |
| Update   | PUT    | `/api/roles/:id`| admin  | `{ name }` |
| Delete   | DELETE | `/api/roles/:id`| admin  | -      |

- **Model**: `Role` – `name` (required, unique).

---

### 2. User (assign to role)

| Action   | Method | Endpoint              | Auth   | Body |
|----------|--------|------------------------|--------|------|
| Register | POST   | `/api/auth/register`  | public | `{ name, email, password, role }` – `role` = role **name** (e.g. `"admin"`, `"seller"`, `"buyer"`) |
| **Create** | POST | `/api/users`          | admin (manage_users) | `{ name, email, password, role }` – create user and assign to existing role by **name** |
| List     | GET    | `/api/users`          | admin (manage_users) | query: `roleId?`, `role?`, `search?`, `page`, `limit` |
| Get one  | GET    | `/api/users/:id`      | -      | -    |
| Update   | PUT    | `/api/users/:id`      | self/admin | `{ name?, email?, role?, ... }` – admin can set **role** (name) |
| Delete   | DELETE | `/api/users/:id`      | self/admin | -    |

- **Model**: `User` – `roleId` (ref `Role`). When creating a user (register or POST /api/users), **role** must be an existing role name.

---

### 3. Menu

| Action   | Method | Endpoint          | Auth   | Body |
|----------|--------|-------------------|--------|------|
| Create   | POST   | `/api/menus`      | admin  | `{ name, path, parentId? }` |
| List     | GET    | `/api/menus`      | none   | query: `parentId?` |
| Get one  | GET    | `/api/menus/:id`  | none   | -    |
| Update   | PUT    | `/api/menus/:id`  | protect| `{ name?, path?, parentId? }` |
| Delete   | DELETE | `/api/menus/:id`  | protect| -    |

- **Model**: `Menu` – `name`, `path`, `parentId` (ref `Menu`), `isActive`, `icon`.

---

### 4. Permission (each has one menu)

| Action   | Method | Endpoint              | Auth   | Body |
|----------|--------|------------------------|--------|------|
| Create   | POST   | `/api/permissions`    | admin  | `{ name, menuId }` – **menuId required** |
| List     | GET    | `/api/permissions`    | admin  | query: `menuId?`, `page`, `limit` |
| Get one  | GET    | `/api/permissions/:id`| admin  | -    |
| Update   | PUT    | `/api/permissions/:id`| admin  | `{ name?, menuId? }` – menuId required if provided |
| Delete   | DELETE | `/api/permissions/:id`| admin  | -    |

- **Model**: `Permission` – `name` (required, unique), **menuId** (ref `Menu`, **required**). Each permission belongs to one menu.

---

### 5. Role–Permission (assign permissions to role)

| Action   | Method | Endpoint                                                    | Auth   | Body / Params |
|----------|--------|-------------------------------------------------------------|--------|----------------|
| Assign   | POST   | `/api/role-permissions`                                    | admin  | `{ roleId, permissionId }` |
| List all | GET    | `/api/role-permissions`                                    | admin  | query: `roleId?`, `permissionId?` |
| By role  | GET    | `/api/role-permissions/role/:roleId`                       | admin  | -             |
| By perm  | GET    | `/api/role-permissions/permission/:permissionId`           | admin  | -             |
| Get one  | GET    | `/api/role-permissions/:id`                                | admin  | -             |
| Update   | PUT    | `/api/role-permissions/:id`                                | admin  | `{ roleId?, permissionId? }` |
| Delete   | DELETE | `/api/role-permissions/:id`                                | admin  | -             |
| Unassign | DELETE | `/api/role-permissions/role/:roleId/permission/:permissionId` | admin | -             |

- **Model**: `RolePermission` – `roleId` (ref `Role`), `permissionId` (ref `Permission`), unique `(roleId, permissionId)`.

---

### 6. Menus for current user

- **GET /api/menus/me** (auth required): Returns menus the user is allowed to see. Logic: user’s role → RolePermission → list of permission IDs → Permission documents (each has menuId) → unique menu IDs → Menu documents (active only). No MenuPermission table.

---

## Auth and authorization

- **protect**: JWT required; sets `req.user` and `req.user.role` from `roleId.name`.
- **authorize("admin", ...)**: allows only if `req.user.role` is in the list.
- **requireAdminOrPermission("permission_name", ...)**: allows if user is admin **or** their role has that permission via RolePermission.
- **checkPermission("permission_name", ...)**: allows only if the user’s role has that permission via RolePermission.

---

## Permission names used by routes

Routes use **admin role OR** one of these permission names (via RolePermission):

| Permission name             | Used for |
|----------------------------|----------|
| `manage_roles`             | All `/api/roles` routes |
| `manage_permissions`       | All `/api/permissions` routes |
| `manage_menus`             | POST/PUT/DELETE `/api/menus` |
| `manage_users`             | GET list, POST create `/api/users` |
| `manage_role_permissions`   | All `/api/role-permissions` routes |
| `manage_settings`           | GET/PUT `/api/settings` |

---

## Seed

Run:

```bash
cd backend
node scripts/seed-rbac.js
```

This creates:

- Roles: **admin**, **seller**, **buyer**
- Admin user: **ali@gmail.com** / **admin123**
- Seller user: **seller@example.com** / **seller123**
- Buyer user: **buyer@example.com** / **buyer123**
- Menus (seller + admin paths)
- Permissions: each with one **menuId** (e.g. `view_seller_dashboard` → `/seller/dashboard`, `manage_users` → `/admin/users`)
- RolePermission: seller gets `view_seller_*`; admin gets all permissions

---

## Frontend implementation (based on this design)

1. **GET /api/menus/me**: Returns permission-filtered menus for the current user. Frontend should filter by path prefix (e.g. `/admin` vs `/seller`) to show the right portal (admin layout vs seller layout). No change to this API’s response shape.
2. **Creating/editing a permission**: Frontend must always send **menuId** (required). When creating a permission, show a menu dropdown or list and set `menuId` to the selected menu. When editing, show the current menu and allow changing it to another menu.
3. **Listing permissions**: Use GET `/api/permissions` (optionally `?menuId=...` to filter by menu). Each permission in the response has `menuId` (and can be populated with menu `name`, `path`). Use this for admin screens: Permissions list, Role Permissions (assign permissions to role), and when creating/editing a permission (pick a menu).
4. **Role Permissions screen**: List permissions (with menu name/path). When assigning a permission to a role, the relationship is only Role + Permission (no menu assignment in this step—menu is already on the permission). Display which menu each permission belongs to so admins understand what they’re granting.
5. **No MenuPermission API**: There is no menu–permission link table. Everything is driven by Permission.menuId and RolePermission. Frontend should not call or show any “link permission to menu” step; creating/editing a permission with a menuId is enough.
