const express = require("express");
const morgan = require("morgan");
const cors = require("cors");
const connectDB = require("./config/db");
require("dotenv").config();

// Define routes
const authRoutes = require("./routes/authRoutes");
const userRoutes = require("./routes/userRoutes");
const BusinessRoutes = require("./routes/businessRoutes");
const adminRoutes = require("./routes/adminRoutes");
const roleRoutes = require("./routes/roleRoutes");
const permissionRoutes = require("./routes/permissionRoutes");
const rolePermissionRoutes = require("./routes/rolePermissionRoutes");
const menuRoutes = require("./routes/menuRoutes");
const contactRoutes = require("./routes/contactRoutes");
const settingRoutes = require("./routes/settingRoutes");
const app = express();

// Connect to the database
connectDB();
const PORT = process.env.PORT || 3000;

// Enable CORS for development (allows Flutter web / Chrome requests)
app.use(cors());
app.use(express.json());
// Add morgan token to log request body (useful for POST/PUT debugging)
morgan.token("body", (req) => {
  try {
    return JSON.stringify(req.body);
  } catch (e) {
    return "";
  }
});

// Custom morgan format that includes method, url, status, response time and body
app.use(
  morgan(":method :url :status :res[content-length] - :response-time ms :body"),
);

app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);
app.use("/api/business", BusinessRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/roles", roleRoutes);
app.use("/api/permissions", permissionRoutes);
app.use("/api/role-permissions", rolePermissionRoutes);
app.use("/api/menus", menuRoutes);
app.use("/api/contacts", contactRoutes);
app.use("/api/settings", settingRoutes);

app.get("/health", (req, res) => {
  res.status(200).send("Server is healthy");
});

// Chrome DevTools sometimes requests this; respond so it doesn't 404 in the console
app.get("/.well-known/appspecific/com.chrome.devtools.json", (req, res) => {
  res.status(200).json({});
});

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
