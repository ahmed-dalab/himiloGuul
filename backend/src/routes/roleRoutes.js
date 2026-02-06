const { Router } = require("express");
const {
  createRole,
  getAllRoles,
  getRoleById,
  updateRole,
  deleteRole,
} = require("../controllers/roleController");
const { protect, requireAdminOrPermission } = require("../middlewares/authMiddleware");

const router = Router();

router.use(protect);
router.use(requireAdminOrPermission("manage_roles"));

// Role management routes
router.post("/", createRole);
router.get("/", getAllRoles);
router.get("/:id", getRoleById);
router.put("/:id", updateRole);
router.delete("/:id", deleteRole);

module.exports = router;
