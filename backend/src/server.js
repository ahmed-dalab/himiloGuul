const express = require("express");
const morgan = require("morgan");
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
const app = express();

// Connect to the database
connectDB();
const PORT = process.env.PORT || 5000;

app.use(express.json());
app.use(morgan("dev"));

app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);
app.use("/api/business", BusinessRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/roles", roleRoutes);
app.use("/api/permissions", permissionRoutes);
app.use("/api/role-permissions", rolePermissionRoutes);
app.use("/api/menus", menuRoutes);
app.use("/api/contacts", contactRoutes);

app.get("/health", (req, res) => {
  res.status(200).send("Server is healthy");
});

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
