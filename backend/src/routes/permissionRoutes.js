const { Router } = require("express");
const {
  createPermission,
  getAllPermissions,
  getPermissionById,
  updatePermission,
  deletePermission,
} = require("../controllers/permissionController");
const { protect, authorize } = require("../middlewares/authMiddleware");

const router = Router();

// All permission routes require authentication and admin role
router.use(protect);
router.use(authorize("admin"));

// Create permission
router.post("/", createPermission);

// Get all permissions
router.get("/", getAllPermissions);

// Get permission by ID
router.get("/:id", getPermissionById);

// Update permission
router.put("/:id", updatePermission);

// Delete permission
router.delete("/:id", deletePermission);

module.exports = router;
