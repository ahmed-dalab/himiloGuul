# Full Guide: Express, Mongoose, Cloudinary, CORS, Body Parser, Middleware, Authentication & Authorization

This documentation teaches each concept step‑by‑step with explanations and code examples, flowing in a connected way.

---

## 1. **Express.js**

Express.js is a minimal and flexible Node.js framework that helps you build APIs and web apps easily.

### Key Features:

- Routing
- Middleware support
- Easy integration with databases

### Installation:

```bash
npm install express
```

### Basic Example:

```js
import express from "express";

const app = express();

app.get("/", (req, res) => {
  res.send("Hello from Express!");
});

app.listen(5000, () => console.log("Server running on port 5000"));
```

---

## 2. **Body Parser**

Body Parser extracts data from the incoming request body (like JSON).

In modern Express versions, body-parser is built‑in.

### Example:

```js
app.use(express.json()); // parse JSON
app.use(express.urlencoded({ extended: true })); // form data
```

This allows you to receive data:

```js
app.post("/data", (req, res) => {
  console.log(req.body);
  res.json({ message: "Data received!" });
});
```

---

## 3. **CORS** (Cross-Origin Resource Sharing)

CORS allows your frontend (like React) to talk to your backend.

### Installation:

```bash
npm install cors
```

### Example:

```js
import cors from "cors";
app.use(cors());
```

To allow specific origins:

```js
app.use(
  cors({
    origin: "http://localhost:3000",
    credentials: true,
  })
);
```

---

## 4. **Middleware**

Middleware are functions that run **between** the request and response.

### Example middleware:

```js
const logger = (req, res, next) => {
  console.log(`${req.method} ${req.url}`);
  next();
};

app.use(logger);
```

### Where middleware is useful:

- Logging
- Error handling
- Authentication
- Validating requests

---

## 5. **Mongoose** (MongoDB ODM)

Mongoose speaks to MongoDB and gives you schemas and models.

### Installation:

```bash
npm install mongoose
```

### Connect to MongoDB:

```js
import mongoose from "mongoose";

mongoose
  .connect(process.env.MONGO_URI)
  .then(() => console.log("MongoDB connected"))
  .catch((err) => console.error(err));
```

### Example Schema & Model:

```js
const userSchema = new mongoose.Schema({
  name: String,
  email: String,
  password: String,
});

const User = mongoose.model("User", userSchema);
```

### Create a document:

```js
const user = await User.create({
  name: "Ahmed",
  email: "test@test.com",
  password: "123",
});
```

---

## 6. **Cloudinary** (Image Uploading)

Cloudinary stores and optimizes images.

### Installation:

```bash
npm install cloudinary
```

### Setup:

```js
import { v2 as cloudinary } from "cloudinary";

cloudinary.config({
  cloud_name: process.env.CLOUD_NAME,
  api_key: process.env.CLOUD_KEY,
  api_secret: process.env.CLOUD_SECRET,
});
```

### Upload image:

```js
const uploadImage = async (filePath) => {
  const result = await cloudinary.uploader.upload(filePath, {
    folder: "uploads",
  });
  return result;
};
```

---

## 7. **Authentication**

Authentication is verifying **who** the user is.

The most common method: **JWT (JSON Web Token)**.

### Install:

```bash
npm install jsonwebtoken bcryptjs
```

### Sign JWT:

```js
import jwt from "jsonwebtoken";

const createToken = (userId) => {
  return jwt.sign({ id: userId }, process.env.JWT_SECRET, { expiresIn: "1d" });
};
```

### Register Example:

```js
import bcrypt from "bcryptjs";

app.post("/register", async (req, res) => {
  const { name, email, password } = req.body;

  const hashed = await bcrypt.hash(password, 10);

  const user = await User.create({ name, email, password: hashed });

  const token = createToken(user._id);

  res.json({ user, token });
});
```

---

## 8. **Authorization**

Authorization determines **what the user is allowed to do**.

Example: admin vs normal user.

### Middleware:

```js
const authMiddleware = (req, res, next) => {
  const token = req.headers.authorization?.split(" ")[1];
  if (!token) return res.status(401).json({ message: "Unauthorized" });

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    res.status(401).json({ message: "Invalid Token" });
  }
};
```

### Role-based Authorization:

```js
const isAdmin = (req, res, next) => {
  if (req.user.role !== "admin") {
    return res.status(403).json({ message: "Access Denied" });
  }
  next();
};
```

### Using Both:

```js
app.get("/admin", authMiddleware, isAdmin, (req, res) => {
  res.send("Welcome Admin");
});
```

---

## Final Flow (Putting All Together)

1. Express creates server
2. Body Parser reads request body
3. CORS allows frontend access
4. Middleware logs and protects routes
5. Mongoose stores data
6. Cloudinary uploads images
7. Authentication verifies user
8. Authorization controls access

Everything works together to create a strong and modern backend system.

---

If you want, I can extend this documentation with folder structure, advanced examples, or convert it into a full PDF or course-style curriculum.
