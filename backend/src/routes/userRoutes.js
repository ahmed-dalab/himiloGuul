const { Router } = require("express");
const {
  createUser,
  getAllUsers,
  getUserById,
  getUserProfile,
  updateUserProfile,
  updateUser,
  deleteUser,
} = require("../controllers/userController");
const { protect, requirePermission, requireAdminOrPermission, requireSellerOrBuyerOrPermission, requireSelfOrAdminOrPermission } = require("../middlewares/authMiddleware");

const router = Router();

// Protected routes
// Note: /profile routes must come before /:id routes to avoid route conflicts

router.post("/", protect, requireAdminOrPermission("manage_users"), createUser);
router.get("/profile", protect, requireSellerOrBuyerOrPermission("view_profile"), getUserProfile);
router.put("/profile", protect, requireSellerOrBuyerOrPermission("update_profile"), updateUserProfile);
router.get("/", protect, requireAdminOrPermission("manage_users"), getAllUsers);

// GET /api/users/:id - Get user public info (no auth)
router.get("/:id", getUserById);

router.put("/:id", protect, requireSelfOrAdminOrPermission("manage_users"), updateUser);
router.delete("/:id", protect, requireSelfOrAdminOrPermission("manage_users"), deleteUser);

module.exports = router;
