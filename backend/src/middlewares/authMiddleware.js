const jwt = require("jsonwebtoken");
const User = require("../models/User");

// Protect routes - verify JWT token
const protect = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({ message: "No token provided" });
    }

    const token = authHeader.split(" ")[1];

    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      const user = await User.findById(decoded.id).populate("roleId", "name");
      
      if (!user) {
        return res.status(401).json({ message: "User not found" });
      }

      if (user.isBanned) {
        return res.status(403).json({ message: "User is banned" });
      }

      // Ensure role is set in req.user for use in authorize middleware
      if (user.roleId) {
        user.role = user.roleId.name;
      } else {
        user.role = null;
      }

      req.user = user;
      next();
    } catch (err) {
      return res.status(401).json({ message: "Invalid or expired token" });
    }
  } catch (error) {
    return res
      .status(500)
      .json({ message: "Server error", error: error.message });
  }
};

// Authorize based on roles
const authorize = (...roles) => {
  return async (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ message: "Not authenticated" });
    }

    // Ensure role is populated from roleId if not already set
    if (!req.user.role && req.user.roleId) {
      await req.user.populate("roleId", "name");
      if (req.user.roleId) {
        req.user.role = req.user.roleId.name;
      }
    }

    // Use role from req.user (set by protect middleware)
    const userRole = req.user.role;

    if (!userRole || !roles.includes(userRole)) {
      return res
        .status(403)
        .json({ message: "Access denied. Insufficient permissions" });
    }

    next();
  };
};

module.exports = { protect, authorize };
