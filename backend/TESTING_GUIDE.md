# Testing Guide for User Endpoints

## Prerequisites

1. **Environment Variables** - Create a `.env` file in the root directory:
```env
MONGO_URI=your_mongodb_connection_string
JWT_SECRET=your_secret_key_here
PORT=5000
```

2. **Seed roles** (first time only; creates admin, user, buyer, seller if missing):
```bash
npm run seed:roles
```

3. **Start the Server**:
```bash
npm run dev
```

The server will run on `http://localhost:5000` (or your configured PORT).

4. **Run API integration tests** (optional):
```bash
npm run test:api
```

---

## Testing Methods

### Method 1: Using Postman (Recommended)

#### Step 1: Register a User
- **Method**: `POST`
- **URL**: `http://localhost:5000/api/auth/register`
- **Headers**: `Content-Type: application/json`
- **Body** (raw JSON):
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "role": "user"
}
```

**Expected Response**: User object and token

#### Step 2: Login
- **Method**: `POST`
- **URL**: `http://localhost:5000/api/auth/login`
- **Headers**: `Content-Type: application/json`
- **Body** (raw JSON):
```json
{
  "email": "john@example.com",
  "password": "password123"
}
```

**Expected Response**: User object and token
**Important**: Copy the `token` from the response - you'll need it for protected routes!

#### Step 3: Get Current User Profile
- **Method**: `GET`
- **URL**: `http://localhost:5000/api/users/profile`
- **Headers**: 
  - `Content-Type: application/json`
  - `Authorization: Bearer YOUR_TOKEN_HERE`

**Expected Response**: Current user's profile

#### Step 4: Update Own Profile
- **Method**: `PUT`
- **URL**: `http://localhost:5000/api/users/profile`
- **Headers**: 
  - `Content-Type: application/json`
  - `Authorization: Bearer YOUR_TOKEN_HERE`
- **Body** (raw JSON):
```json
{
  "name": "John Updated",
  "phone": "+1234567890",
  "location": "New York",
  "profilePicture": "https://res.cloudinary.com/example/image.jpg"
}
```

**Expected Response**: Updated user profile

#### Step 5: Get User by ID (Public)
- **Method**: `GET`
- **URL**: `http://localhost:5000/api/users/USER_ID_HERE`
- **Headers**: None required (public endpoint)

**Expected Response**: Public user information

#### Step 6: Update User by ID (Self or Admin)
- **Method**: `PUT`
- **URL**: `http://localhost:5000/api/users/USER_ID_HERE`
- **Headers**: 
  - `Content-Type: application/json`
  - `Authorization: Bearer YOUR_TOKEN_HERE`
- **Body** (raw JSON):
```json
{
  "name": "Updated Name",
  "phone": "+9876543210",
  "location": "Los Angeles"
}
```

**Expected Response**: Updated user object

#### Step 7: Get All Users (Admin Only)
- **Method**: `GET`
- **URL**: `http://localhost:5000/api/users`
- **Headers**: 
  - `Content-Type: application/json`
  - `Authorization: Bearer ADMIN_TOKEN_HERE`

**Expected Response**: List of all users

---

### Method 2: Using cURL (Command Line)

#### Register User
```bash
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "password": "password123",
    "role": "user"
  }'
```

#### Login
```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "password123"
  }'
```

#### Get Profile (Replace YOUR_TOKEN with actual token)
```bash
curl -X GET http://localhost:5000/api/users/profile \
  -H "Authorization: Bearer YOUR_TOKEN"
```

#### Update Profile
```bash
curl -X PUT http://localhost:5000/api/users/profile \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "name": "John Updated",
    "phone": "+1234567890",
    "location": "New York"
  }'
```

#### Get User by ID
```bash
curl -X GET http://localhost:5000/api/users/USER_ID_HERE
```

#### Update User by ID
```bash
curl -X PUT http://localhost:5000/api/users/USER_ID_HERE \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "name": "Updated Name",
    "phone": "+9876543210"
  }'
```

---

### Method 3: Using JavaScript/Node.js (Test Script)

Create a file `test-endpoints.js`:

```javascript
const axios = require('axios');

const API = 'http://localhost:5000/api';
const AUTH_URL = `${API}/auth`;
const USERS_URL = `${API}/users`;

let token = '';
let userId = '';

async function testEndpoints() {
  try {
    // 1. Register
    console.log('1. Registering user...');
    const registerRes = await axios.post(`${AUTH_URL}/register`, {
      name: 'Test User',
      email: 'test@example.com',
      password: 'password123',
      role: 'user'
    });
    console.log('Register Response:', registerRes.data);
    token = registerRes.data.token;
    userId = registerRes.data.user._id;

    // 2. Login
    console.log('\n2. Logging in...');
    const loginRes = await axios.post(`${AUTH_URL}/login`, {
      email: 'test@example.com',
      password: 'password123'
    });
    console.log('Login Response:', loginRes.data);
    token = loginRes.data.token;

    // 3. Get Profile
    console.log('\n3. Getting profile...');
    const profileRes = await axios.get(`${USERS_URL}/profile`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    console.log('Profile Response:', profileRes.data);

    // 4. Update Profile
    console.log('\n4. Updating profile...');
    const updateRes = await axios.put(`${USERS_URL}/profile`, {
      name: 'Updated Name',
      phone: '+1234567890',
      location: 'New York'
    }, {
      headers: { Authorization: `Bearer ${token}` }
    });
    console.log('Update Response:', updateRes.data);

    // 5. Get User by ID
    console.log('\n5. Getting user by ID...');
    const userRes = await axios.get(`${USERS_URL}/${userId}`);
    console.log('User Response:', userRes.data);

    // 6. Update User by ID
    console.log('\n6. Updating user by ID...');
    const updateByIdRes = await axios.put(`${USERS_URL}/${userId}`, {
      name: 'Final Name',
      phone: '+9876543210'
    }, {
      headers: { Authorization: `Bearer ${token}` }
    });
    console.log('Update by ID Response:', updateByIdRes.data);

    console.log('\n✅ All tests completed!');
  } catch (error) {
    console.error('❌ Error:', error.response?.data || error.message);
  }
}

testEndpoints();
```

Run with:
```bash
npm install axios
node test-endpoints.js
```

---

## Testing Checklist

- [ ] Register a new user
- [ ] Login with credentials
- [ ] Get current user profile (with token)
- [ ] Update own profile (with token)
- [ ] Get user by ID (public, no token)
- [ ] Update user by ID (with token - self)
- [ ] Try accessing protected route without token (should fail)
- [ ] Try accessing protected route with invalid token (should fail)
- [ ] Try updating another user's profile (should fail unless admin)
- [ ] Get all users as admin (should work)
- [ ] Get all users as regular user (should fail)

---

## Common Issues

1. **"No token provided"** - Make sure you include `Authorization: Bearer TOKEN` header
2. **"Invalid or expired token"** - Token might be expired or invalid, try logging in again
3. **"User is banned"** - User account is banned, check `isBanned` field
4. **"Access denied"** - You don't have permission (e.g., trying to access admin route as regular user)
5. **Connection refused** - Make sure the server is running (`npm run dev`)
6. **MongoDB connection error** - Check your `MONGO_URI` in `.env` file

---

## Quick Test with Postman Collection

You can also import this as a Postman collection:

1. Open Postman
2. Click "Import"
3. Create a new collection
4. Add requests for each endpoint
5. Set up environment variables:
   - `base_url`: `http://localhost:5000`
   - `token`: (will be set after login)

