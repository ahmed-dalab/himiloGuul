# HimiloGuul Backend

REST API for the HimiloGuul business marketplace (auth, users, businesses, contacts, roles, permissions, menus).

## Quick start

```bash
# Install deps
npm install

# Configure .env with MONGO_URI, JWT_SECRET, PORT; optionally CLOUDINARY_* for image uploads

# Seed roles (first time)
npm run seed:roles

# Run
npm run dev
```

## Scripts

| Script       | Description                                      |
|-------------|--------------------------------------------------|
| `npm run dev`       | Start server with nodemon                        |
| `npm run seed:roles`| Create default roles (admin, user, buyer, seller)|
| `npm run test:api`  | Run API integration tests (server must be running) |

## API overview

| Base path        | Purpose                          |
|------------------|----------------------------------|
| `/api/auth`      | Login, register                   |
| `/api/users`     | Profile, by ID, list (admin)     |
| `/api/business`  | Browse, by ID, /my, CRUD, approve, mark sold |
| `/api/admin`     | Businesses, users, contacts (admin) |
| `/api/roles`     | Role CRUD (admin)                |
| `/api/permissions` | Permission CRUD (admin)       |
| `/api/role-permissions` | Assign permissions to roles (admin) |
| `/api/menus`     | Menu CRUD, list                  |
| `/api/contacts`  | Create, my, by ID, update, delete |

See **TESTING_GUIDE.md** for request/response examples and Postman/cURL samples.
