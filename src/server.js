const express = require("express");
const morgan = require("morgan");
const connectDB = require("./config/db");
require("dotenv").config();

// Define routes
const userRoutes = require("./routes/userRoutes");
const BusinessRoutes = require("./routes/businessRoutes");
const adminUserRoutes = require("./routes/adminUserRoutes");
const menuRoutes = require("./routes/menuRoutes");
const app = express();

// Connect to the database
connectDB();
const PORT = process.env.PORT || 5000;

app.use(express.json());
app.use(morgan("dev"));

app.use("/api/users", userRoutes);
app.use("/api/business", BusinessRoutes);
app.use("/api/admin", adminUserRoutes);
app.use("/api/menus", menuRoutes);

app.get("/", (req, res) => {
  res.send("API is running...");
});

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
