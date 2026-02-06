const jwt = require("jsonwebtoken");
const User = require("../models/User");
const RolePermission = require("../models/RolePermission");
const Permission = require("../models/Permission");

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

      // Attach permission names for the user's role (permission-driven auth)
      // This makes permission checks fast and consistent across the app.
      if (user.roleId) {
        const rolePermissions = await RolePermission.find({ roleId: user.roleId._id || user.roleId })
          .populate("permissionId", "name")
          .select("permissionId");

        user.permissions = rolePermissions
          .map((rp) => rp.permissionId && rp.permissionId.name)
          .filter(Boolean);
      } else {
        user.permissions = [];
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

/**
 * Check permissions based on RolePermission relationships
 * This middleware checks if the user's role has the specified permission(s)
 *
 * @param {...string} permissionNames - One or more permission names to check
 */
const checkPermission = (...permissionNames) => {
  return async (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ message: "Not authenticated" });
    }

    if (!req.user.role && req.user.roleId) {
      await req.user.populate("roleId", "name");
      if (req.user.roleId) {
        req.user.role = req.user.roleId.name;
      }
    }

    if (!req.user.roleId) {
      return res
        .status(403)
        .json({ message: "Access denied. User has no role assigned" });
    }

    try {
      const permissions = await Permission.find({
        name: { $in: permissionNames },
      });

      if (permissions.length === 0) {
        return res.status(403).json({
          message: "Access denied. Invalid permission(s) specified",
        });
      }

      const permissionIds = permissions.map((p) => p._id);
      const rolePermission = await RolePermission.findOne({
        roleId: req.user.roleId,
        permissionId: { $in: permissionIds },
      });

      if (!rolePermission) {
        return res
          .status(403)
          .json({ message: "Access denied. Insufficient permissions" });
      }

      next();
    } catch (error) {
      return res
        .status(500)
        .json({ message: "Server error", error: error.message });
    }
  };
};

/**
 * Allow access if user has role "admin" OR if user's role has any of the given permissions.
 * Use this so: after seed, admin (role admin) can access everything; when you create
 * permissions and assign them to roles, those roles get access too.
 *
 * @param {...string} permissionNames - Permission names (e.g. manage_users, manage_roles)
 */
const requireAdminOrPermission = (...permissionNames) => {
  return async (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ message: "Not authenticated" });
    }

    if (!req.user.role && req.user.roleId) {
      await req.user.populate("roleId", "name");
      if (req.user.roleId) {
        req.user.role = req.user.roleId.name;
      }
    }

    // Admin role always allowed (so seed admin can do everything before permissions exist)
    if (req.user.role === "admin") {
      return next();
    }

    if (!req.user.roleId) {
      return res
        .status(403)
        .json({ message: "Access denied. User has no role assigned" });
    }

    try {
      const permissions = await Permission.find({
        name: { $in: permissionNames },
      });

      if (permissions.length === 0) {
        return res.status(403).json({
          message: "Access denied. Invalid permission(s) specified",
        });
      }

      const permissionIds = permissions.map((p) => p._id);
      const rolePermission = await RolePermission.findOne({
        roleId: req.user.roleId,
        permissionId: { $in: permissionIds },
      });

      if (!rolePermission) {
        return res
          .status(403)
          .json({ message: "Access denied. Insufficient permissions" });
      }

      next();
    } catch (error) {
      return res
        .status(500)
        .json({ message: "Server error", error: error.message });
    }
  };
};

/**
 * Allow access if user has role "seller" OR if user's role has any of the given permissions.
 */
const requireSellerOrPermission = (...permissionNames) => {
  return async (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ message: "Not authenticated" });
    }
    if (!req.user.role && req.user.roleId) {
      await req.user.populate("roleId", "name");
      if (req.user.roleId) req.user.role = req.user.roleId.name;
    }
    if (req.user.role === "seller") return next();
    if (!req.user.roleId) {
      return res.status(403).json({ message: "Access denied. User has no role assigned" });
    }
    try {
      const permissions = await Permission.find({ name: { $in: permissionNames } });
      if (permissions.length === 0) {
        return res.status(403).json({ message: "Access denied. Invalid permission(s) specified" });
      }
      const permissionIds = permissions.map((p) => p._id);
      const rolePermission = await RolePermission.findOne({
        roleId: req.user.roleId,
        permissionId: { $in: permissionIds },
      });
      if (!rolePermission) {
        return res.status(403).json({ message: "Access denied. Insufficient permissions" });
      }
      next();
    } catch (error) {
      return res.status(500).json({ message: "Server error", error: error.message });
    }
  };
};

/**
 * Allow access if user has role "buyer" OR if user's role has any of the given permissions.
 */
const requireBuyerOrPermission = (...permissionNames) => {
  return async (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ message: "Not authenticated" });
    }
    if (!req.user.role && req.user.roleId) {
      await req.user.populate("roleId", "name");
      if (req.user.roleId) req.user.role = req.user.roleId.name;
    }
    if (req.user.role === "buyer") return next();
    if (!req.user.roleId) {
      return res.status(403).json({ message: "Access denied. User has no role assigned" });
    }
    try {
      const permissions = await Permission.find({ name: { $in: permissionNames } });
      if (permissions.length === 0) {
        return res.status(403).json({ message: "Access denied. Invalid permission(s) specified" });
      }
      const permissionIds = permissions.map((p) => p._id);
      const rolePermission = await RolePermission.findOne({
        roleId: req.user.roleId,
        permissionId: { $in: permissionIds },
      });
      if (!rolePermission) {
        return res.status(403).json({ message: "Access denied. Insufficient permissions" });
      }
      next();
    } catch (error) {
      return res.status(500).json({ message: "Server error", error: error.message });
    }
  };
};

/**
 * Allow access if user has role "seller" or "buyer" OR if user's role has any of the given permissions.
 */
const requireSellerOrBuyerOrPermission = (...permissionNames) => {
  return async (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ message: "Not authenticated" });
    }
    if (!req.user.role && req.user.roleId) {
      await req.user.populate("roleId", "name");
      if (req.user.roleId) req.user.role = req.user.roleId.name;
    }
    if (req.user.role === "seller" || req.user.role === "buyer") return next();
    if (!req.user.roleId) {
      return res.status(403).json({ message: "Access denied. User has no role assigned" });
    }
    try {
      const permissions = await Permission.find({ name: { $in: permissionNames } });
      if (permissions.length === 0) {
        return res.status(403).json({ message: "Access denied. Invalid permission(s) specified" });
      }
      const permissionIds = permissions.map((p) => p._id);
      const rolePermission = await RolePermission.findOne({
        roleId: req.user.roleId,
        permissionId: { $in: permissionIds },
      });
      if (!rolePermission) {
        return res.status(403).json({ message: "Access denied. Insufficient permissions" });
      }
      next();
    } catch (error) {
      return res.status(500).json({ message: "Server error", error: error.message });
    }
  };
};

/**
 * Allow access if user has role "admin", "seller", or "buyer" OR if user's role has any of the given permissions.
 * Use for routes that admin, seller, and buyer can all access (e.g. view contact by id).
 */
const requireAdminOrSellerOrBuyerOrPermission = (...permissionNames) => {
  return async (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ message: "Not authenticated" });
    }
    if (!req.user.role && req.user.roleId) {
      await req.user.populate("roleId", "name");
      if (req.user.roleId) req.user.role = req.user.roleId.name;
    }
    if (req.user.role === "admin" || req.user.role === "seller" || req.user.role === "buyer") return next();
    if (!req.user.roleId) {
      return res.status(403).json({ message: "Access denied. User has no role assigned" });
    }
    try {
      const permissions = await Permission.find({ name: { $in: permissionNames } });
      if (permissions.length === 0) {
        return res.status(403).json({ message: "Access denied. Invalid permission(s) specified" });
      }
      const permissionIds = permissions.map((p) => p._id);
      const rolePermission = await RolePermission.findOne({
        roleId: req.user.roleId,
        permissionId: { $in: permissionIds },
      });
      if (!rolePermission) {
        return res.status(403).json({ message: "Access denied. Insufficient permissions" });
      }
      next();
    } catch (error) {
      return res.status(500).json({ message: "Server error", error: error.message });
    }
  };
};

/**
 * Require that the authenticated user's role has at least one of the given permissions.
 * This uses DB-backed RolePermission + Permission records (attached by `protect`).
 *
 * @param {...string} permissionNames - Permission names to allow (OR logic)
 */
const requirePermission = (...permissionNames) => {
  return async (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ message: "Not authenticated" });
    }
    const userPermissionNames = Array.isArray(req.user.permissions) ? req.user.permissions : [];
    const allowed = permissionNames.some((p) => userPermissionNames.includes(p));
    if (!allowed) {
      return res.status(403).json({ message: "Access denied. Insufficient permissions" });
    }
    next();
  };
};

/**
 * Allow if the user is acting on themselves (req.params[paramName]), otherwise require permission.
 * Useful for routes like PUT/DELETE /users/:id where self-access is allowed.
 */
const requireSelfOrPermission = (permissionName, paramName = "id") => {
  return async (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ message: "Not authenticated" });
    }

    const targetId = req.params?.[paramName];
    if (targetId && req.user._id && req.user._id.toString() === String(targetId)) {
      return next();
    }

    return requirePermission(permissionName)(req, res, next);
  };
};

/**
 * Allow if the user is acting on themselves, or has role admin, or has the given permission.
 * Use for routes where admin should always be able to act on any user (e.g. update/delete user).
 */
const requireSelfOrAdminOrPermission = (permissionName, paramName = "id") => {
  return async (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ message: "Not authenticated" });
    }

    const targetId = req.params?.[paramName];
    if (targetId && req.user._id && req.user._id.toString() === String(targetId)) {
      return next();
    }

    return requireAdminOrPermission(permissionName)(req, res, next);
  };
};

module.exports = {
  protect,
  authorize,
  checkPermission,
  requireAdminOrPermission,
  requireSellerOrPermission,
  requireBuyerOrPermission,
  requireSellerOrBuyerOrPermission,
  requireAdminOrSellerOrBuyerOrPermission,
  requirePermission,
  requireSelfOrPermission,
  requireSelfOrAdminOrPermission,
};
