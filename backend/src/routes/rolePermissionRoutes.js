const { Router } = require("express");
const {
  createRolePermission,
  getAllRolePermissions,
  getRolePermissionById,
  getPermissionsByRole,
  getRolesByPermission,
  updateRolePermission,
  deleteRolePermission,
  deleteRolePermissionByRoleAndPermission,
} = require("../controllers/rolePermissionController");
const { protect, requireAdminOrPermission } = require("../middlewares/authMiddleware");

const router = Router();

// All role-permission routes require authentication and admin role OR permission "manage_role_permissions"
router.use(protect);
router.use(requireAdminOrPermission("manage_role_permissions"));

// Create role-permission assignment
router.post("/", createRolePermission);

// Get all role-permission assignments
router.get("/", getAllRolePermissions);

// Get permissions for a specific role
router.get("/role/:roleId", getPermissionsByRole);

// Get roles for a specific permission
router.get("/permission/:permissionId", getRolesByPermission);

// Get role-permission assignment by ID
router.get("/:id", getRolePermissionById);

// Update role-permission assignment
router.put("/:id", updateRolePermission);

// Delete by roleId and permissionId (must be before /:id to avoid "role" matching as id)
router.delete("/role/:roleId/permission/:permissionId", deleteRolePermissionByRoleAndPermission);
// Delete role-permission assignment by ID
router.delete("/:id", deleteRolePermission);

module.exports = router;
