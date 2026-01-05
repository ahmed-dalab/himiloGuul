# Team Tasks Breakdown

## 👤 Ahmed - Business Browsing & Cloudinary

### 1. Database Schemas

- [ ] Create **Role** model (name field only)
- [ ] Update **User** model: add `roleId` field

### 2. Cloudinary Setup

- [ ] Configure Cloudinary connection
- [ ] Create image upload middleware
- [ ] Handle multiple image uploads
- [ ] Delete images when business is deleted
- [ ] Validate image types and sizes

### 3. Business Browsing API

- [ ] `GET /api/business` - Browse businesses with:
  - Filter by category
  - Filter by location
  - Filter by price range
  - Search by name/description
  - Pagination
  - Sorting

### 4. Admin Business Management

- [ ] `GET /api/admin/businesses` - List all businesses
- [ ] `GET /api/admin/businesses/pending` - List pending businesses
- [ ] `PUT /api/admin/businesses/:id/approve` - Approve business
- [ ] `PUT /api/admin/businesses/:id/reject` - Reject business

---

## 👤 Nasteha - User Profiles & Management

### 1. Database Schemas

- [ ] Create **Menu** model (name, path, parentId fields)
- [ ] Update **User** model:
  - Add `phone` field
  - Add `location` field
  - Add `profilePicture` field (Cloudinary URL)
  - Add `isBanned` field (boolean, default false)
  - Add email format validation
  - Add indexes for email and role

### 2. Profile Endpoints

- [ ] `GET /api/users/profile` - Get current user profile
- [ ] `PUT /api/users/profile` - Update own profile
- [ ] `GET /api/users/:id` - Get user public info
- [ ] `PUT /api/users/:id` - Update user (self or admin)

### 3. Admin User Management

- [ ] `GET /api/admin/users` - List all users
- [ ] `PUT /api/admin/users/:id/ban` - Ban/unban user
- [ ] `DELETE /api/admin/users/:id` - Delete user

---

## 👤 Iidle - Business CRUD Operations

### 1. Database Schemas

- [ ] Create **Permission** model (name, menuId fields)
- [ ] Update **Business** model:
  - Add `owner` field (User reference)
  - Add `description` field
  - Add `category` field (enum: restaurant, retail, service, etc.)
  - Add `askingPrice` field (number)
  - Add `location` field
  - Add `images` array (url, publicId)
  - Add `status` field (pending, approved, rejected)
  - Add `isSold` field (boolean)
  - Add proper indexes

### 2. Business CRUD Endpoints

- [ ] `POST /api/business` - Create business
- [ ] `GET /api/business/my` - Get my businesses
- [ ] `GET /api/business/:id` - Get business by ID
- [ ] `PUT /api/business/:id` - Update business
- [ ] `DELETE /api/business/:id` - Delete business

---

## 👤 Alasow - Contact System & Permissions

### 1. Database Schemas

- [ ] Create **RolePermission** model (roleId, permissionId fields)
- [ ] Create **Contact** model:
  - `buyerRef` (User reference)
  - `sellerRef` (User reference)
  - `businessRef` (Business reference)
  - `message` field (text)
  - `status` field (pending, responded, closed)
  - Ensure unique contact per buyer-seller-business
  - Add timestamps

### 2. Contact Endpoints

- [ ] `POST /api/contacts` - Create contact
- [ ] `GET /api/contacts/my` - Get my contacts
- [ ] `GET /api/contacts/:id` - Get contact details
- [ ] `PUT /api/contacts/:id` - Update contact
- [ ] `DELETE /api/contacts/:id` - Delete contact

### 3. Admin Contact Management

- [ ] `GET /api/admin/contacts` - List all contacts
- [ ] `DELETE /api/admin/contacts/:id` - Delete contact
