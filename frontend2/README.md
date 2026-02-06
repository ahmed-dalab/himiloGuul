# HimiloGuul Admin (Next.js)

Admin UI for the HimiloGuul backend. Connects to the Node/Express API for roles, users, menus, permissions, and role-permission assignments.

## Setup

1. **Backend** must be running (see `backend/`). Default: `http://localhost:3001`.

2. **Environment**  
   Copy the example env and set the API URL if needed:
   ```bash
   cp .env.local.example .env.local
   ```
   Edit `.env.local`: `NEXT_PUBLIC_API_URL=http://localhost:3001/api`

3. **Install and run**
   ```bash
   npm install
   npm run dev
   ```
   Frontend runs on **http://localhost:3000** (backend on 3001). Open [http://localhost:3000](http://localhost:3000). You’ll be redirected to login.

## Flow (matches backend)

1. **Roles** – Create roles (e.g. admin, seller, buyer).
2. **Users** – Create users and assign an existing role; or register (public) with a role.
3. **Menus** – Create menu items (name, path).
4. **Permissions** – Create permissions; each permission is linked to one menu.
5. **Role Permissions** – Assign permissions to roles.

After login, use the sidebar: Dashboard, Roles, Users, Menus, Permissions, Role Permissions.

## Backend + Frontend integration

With the backend running and logged in as **admin**, you can:

- **Roles** – Create, edit, delete roles (e.g. admin, seller, buyer).
- **Users** – Create users (name, email, password, role), edit, ban/unban, delete.
- **Menus** – Create menus (name, path), edit, delete.
- **Permissions** – Create permissions (name + menu), edit, delete. Create at least one menu first.
- **Role Permissions** – Assign a permission to a role; remove assignments. Needs at least one role and one permission.

**Other models** (admin/seller):

- **Admin:** Dashboard (stats, activity), Businesses (list all, pending, approve/reject), Contacts (list, delete).
- **Seller:** My businesses (CRUD, multi-step form, optional images), Inquiries (contacts about your listings).

API base URL is set via `NEXT_PUBLIC_API_URL` (default `http://localhost:3001/api` when unset).

## Seed data

Run the backend seed to get an admin user and sample data:

```bash
cd backend
node scripts/seed-rbac.js
```

Then log in with **ali@gmail.com** / **admin123**.
