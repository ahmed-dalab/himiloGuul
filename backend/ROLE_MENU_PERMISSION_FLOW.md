# RBAC: Role-Based Access Control with Permission-Driven Menu Visibility

This document describes the backend flow and API for roles, permissions, and menus.

## Core rules

- **Users** are assigned one **role**.
- **Roles** have multiple **permissions** (via RolePermission).
- **Menus** are not assigned directly to users or roles.
- **Each menu** is linked to one or more **permissions** (via MenuPermission).
- **A user sees a menu** if and only if they have at least one permission associated with that menu (via their role).
- Menu visibility is **permission-based**, not hard-coded by role.
- Menus the user does not have permission for are **hidden** (not disabled).
- Backend APIs **still enforce permission checks** regardless of menu visibility.

## Flow

1. **Create role** → store in DB  
2. **Create user** → assign to a role (user has `roleId`)  
3. **Create menu** → store in DB  
4. **Create permission** → optionally link to a primary menu (`menuId`) for display  
5. **Link permission to menu(s)** → MenuPermission (menuId, permissionId) – one permission can unlock multiple menus  
6. **Assign permission to role** → RolePermission (roleId, permissionId)

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
| Register | POST   | `/api/auth/register`  | public | `{ name, email, password, role }` – `role` = role **name** (e.g. `"admin"`) |
| Update   | PUT    | `/api/users/:id`      | self/admin | `{ role }` – role **name** |

- **Model**: `User` – `roleId` (ref `Role`).
- Register and update resolve `role` (name) to `roleId` and save.

---

### 3. Menu

| Action   | Method | Endpoint          | Auth   | Body |
|----------|--------|-------------------|--------|------|
| Create   | POST   | `/api/menus`      | admin  | `{ name, path, parentId? }` |
| List     | GET    | `/api/menus`      | none   | query: `parentId?` |
| Get one  | GET    | `/api/menus/:id`  | none   | -    |
| Update   | PUT    | `/api/menus/:id`  | protect| `{ name?, path?, parentId? }` |
| Delete   | DELETE | `/api/menus/:id`  | protect| -    |

- **Model**: `Menu` – `name`, `path`, `parentId` (ref `Menu`).

---

### 4. Permission

| Action   | Method | Endpoint              | Auth   | Body |
|----------|--------|------------------------|--------|------|
| Create   | POST   | `/api/permissions`    | admin  | `{ name, menuId? }` |
| List     | GET    | `/api/permissions`    | admin  | query: `menuId?`, `page`, `limit` |
| Get one  | GET    | `/api/permissions/:id`| admin  | -    |
| Update   | PUT    | `/api/permissions/:id`| admin  | `{ name?, menuId? }` |
| Delete   | DELETE | `/api/permissions/:id`| admin  | -    |

- **Model**: `Permission` – `name` (required, unique), `menuId` (ref `Menu`, optional – primary menu for display).
- Menu visibility is driven by **MenuPermission** (permission → menu links); a permission can unlock multiple menus.

---

### 5. Menu–Permission (which menus a permission unlocks)

- **Model**: `MenuPermission` – `menuId` (ref `Menu`), `permissionId` (ref `Permission`), unique `(menuId, permissionId)`.
- A menu can be linked to one or more permissions; a permission can unlock one or more menus.
- **GET /api/menus/me** (auth required): returns only menus the user has at least one permission for (via RolePermission → permission IDs → MenuPermission → menu IDs). No role-based hardcoding; admin sees only menus they have permissions for.

### 6. Role–Permission (permissions belong to role)

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
- This is the relationship that makes permissions “belong to” a role.

---

## Auth and authorization

- **protect**: JWT required; sets `req.user` and `req.user.role` from `roleId.name`.
- **authorize("admin", ...)**: allows only if `req.user.role` is in the list.
- **checkPermission("permission_name", ...)**: allows only if the user’s role has that permission via `RolePermission` (OR logic if multiple names).

---

## Permission names used by the backend

Routes use **admin role OR** one of these permission names (via RolePermission):

| Permission name             | Used for |
|----------------------------|----------|
| `manage_roles`             | All `/api/roles` routes |
| `manage_permissions`       | All `/api/permissions` routes |
| `manage_menus`             | POST/PUT/DELETE `/api/menus` |
| `manage_users`             | GET `/api/users` (list all users) |
| `manage_role_permissions`  | All `/api/role-permissions` routes |

**Standardized permission names (e.g. from `seed-rbac.js`):**

- **View (seller/admin):** `view_home`, `view_business`, `view_contacts`, `view_profile`
- **Manage (admin):** `manage_users`, `manage_roles`, `manage_permissions`, `manage_role_permissions`, `manage_menus`, `manage_settings`

Admin role is assigned all of the above via RolePermission. Seller role is assigned only the view_* permissions. Backend routes use `requireAdminOrPermission(permissionName)`; admin role is always allowed.

---

## Summary

- **RBAC**: User → Role → RolePermission → Permission; Menu → MenuPermission ← Permission.
- **Menu visibility**: User sees a menu iff their role has at least one permission linked to that menu (MenuPermission). No hard-coded role menus.
- **Seed**: Run `node scripts/seed-rbac.js` to create roles, menus, permissions, MenuPermission links, RolePermission assignments, and admin user.

---

## Frontend/API notes

1. **GET /api/menus/me**: Returns permission-filtered menus for the current user. Frontend filters by path prefix (e.g. `/admin` for admin layout, `/seller` for seller layout) so each portal only shows its menus.
2. **Fallback menus**: When backend fails, frontend shows no menus (empty list) so visibility stays permission-based.
3. **Response shape**: Role/Permission/RolePermission use `data`; Menu uses `menus`.
