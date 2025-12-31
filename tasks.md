<!-- Ahmed Tasks -->

### **Browsing Features**

- [ ] GET /api/business - Browse with filters
  - [ ] Filter by category
  - [ ] Filter by location
  - [ ] Filter by price range
  - [ ] Search by name/description
  - [ ] Pagination
  - [ ] Sorting

### **Cloudinary Integration**

- [ ] Set up Cloudinary config
- [ ] Create upload middleware
- [ ] Handle multiple image uploads
- [ ] Delete images on business delete
- [ ] Validate image types and sizes

### **Admin Business Management**

- [ ] GET /api/admin/businesses - List all businesses
- [ ] GET /api/admin/businesses/pending - List pending
- [ ] PUT /api/admin/businesses/:id/approve - Approve
- [ ] PUT /api/admin/businesses/:id/reject - Reject

<!-- Nasteha Tasks -->

### **Model Tasks**

- [ ] Add phone field to User model
- [ ] Add location field to User model
- [ ] Add profilePicture field (for Cloudinary URL)
- [ ] Add isBanned field (boolean, default false)
- [ ] Add validation for email format
- [ ] Add indexes for email and role

### **Profile Endpoints**

- [ ] GET /api/users/profile - Get current user profile
- [ ] PUT /api/users/profile - Update own profile
- [ ] GET /api/users/:id - Get user public info
- [ ] PUT /api/users/:id - Update user (self or admin)

### **Admin User Management**

- [ ] GET /api/admin/users - List all users
- [ ] PUT /api/admin/users/:id/ban - Ban/unban user
- [ ] DELETE /api/admin/users/:id - Delete user

<!-- Iidle Tasks -->

### **Model Tasks**

- [ ] Add owner field (User reference)
- [ ] Add description field
- [ ] Add category field (enum: restaurant, retail, service, etc.)
- [ ] Add askingPrice field (number)
- [ ] Add location field
- [ ] Add images array (url, publicId)
- [ ] Add status field (pending, approved, rejected)
- [ ] Add isSold field (boolean)
- [ ] Add proper indexes

### **CRUD Endpoints**

- [ ] POST /api/business - Create business
- [ ] GET /api/business/my - Get my businesses
- [ ] GET /api/business/:id - Get business by ID
- [ ] PUT /api/business/:id - Update business
- [ ] DELETE /api/business/:id - Delete business

<!-- Zeyn Tasks -->

### **Model Tasks**

- [ ] Create Contact model
- [ ] Add buyerRef (User reference)
- [ ] Add sellerRef (User reference)
- [ ] Add businessRef (Business reference)
- [ ] Add message field (text)
- [ ] Add status field (pending, responded, closed)
- [ ] Ensure unique contact per buyer-seller-business
- [ ] Add timestamps

### **Contact Endpoints**

- [ ] POST /api/contacts - Create contact
- [ ] GET /api/contacts/my - Get my contacts
- [ ] GET /api/contacts/:id - Get contact details
- [ ] PUT /api/contacts/:id - Update contact
- [ ] DELETE /api/contacts/:id - Delete contact

### **Admin Contact Management**

- [ ] GET /api/admin/contacts - List all contacts
- [ ] DELETE /api/admin/contacts/:id - Delete contact
