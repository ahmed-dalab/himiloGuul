const { Router } = require("express");
const {
  createRole,
  getAllRoles,
  getRoleById,
  updateRole,
  deleteRole,
} = require("../controllers/roleController");
const { protect, authorize } = require("../middlewares/authMiddleware");

const router = Router();

// All role routes require authentication and admin role
router.use(protect);
router.use(authorize("admin"));

// Role management routes
router.post("/", createRole);
router.get("/", getAllRoles);
router.get("/:id", getRoleById);
router.put("/:id", updateRole);
router.delete("/:id", deleteRole);

module.exports = router;
