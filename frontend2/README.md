# HimiloGuul Admin (Next.js)

Admin UI for the HimiloGuul backend. Connects to the Node/Express API for roles, users, menus, permissions, and role-permission assignments.

## Setup

1. **Backend** must be running (see `backend/`). Default: `http://localhost:3000`.

2. **Environment**  
   Copy the example env and set the API URL if needed:
   ```bash
   cp .env.local.example .env.local
   ```
   Edit `.env.local`: `NEXT_PUBLIC_API_URL=http://localhost:3000/api`

3. **Install and run**
   ```bash
   npm install
   npm run dev
   ```
   Frontend runs on **http://localhost:3001** (backend on 3000). Open [http://localhost:3001](http://localhost:3001). You’ll be redirected to login.

## Flow (matches backend)

1. **Roles** – Create roles (e.g. admin, seller, buyer).
2. **Users** – Create users and assign an existing role; or register (public) with a role.
3. **Menus** – Create menu items (name, path).
4. **Permissions** – Create permissions; each permission is linked to one menu.
5. **Role Permissions** – Assign permissions to roles.

After login, use the sidebar: Dashboard, Roles, Users, Menus, Permissions, Role Permissions.

## Seed data

Run the backend seed to get an admin user and sample data:

```bash
cd backend
node scripts/seed-rbac.js
```

Then log in with **ali@gmail.com** / **admin123**.
