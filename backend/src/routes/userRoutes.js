const { Router } = require("express");
const {
  getAllUsers,
  getUserById,
  getUserProfile,
  updateUserProfile,
  updateUser,
  deleteUser,
} = require("../controllers/userController");
const { protect, requireAdminOrPermission } = require("../middlewares/authMiddleware");

const router = Router();

// Protected routes (authentication required)
// Note: /profile routes must come before /:id routes to avoid route conflicts

// GET /api/users/profile - Get current user profile
router.get("/profile", protect, getUserProfile);

// PUT /api/users/profile - Update own profile
router.put("/profile", protect, updateUserProfile);

// GET /api/users/:id - Get user public info
router.get("/:id", getUserById);

// PUT /api/users/:id - Update user (self or admin)
router.put("/:id", protect, updateUser);

// DELETE /api/users/:id - Delete user (admin and the user himself can access)
router.delete("/:id", protect, deleteUser);

// GET /api/users - Get all users: admin OR permission "manage_users"
router.get("/", protect, requireAdminOrPermission("manage_users"), getAllUsers);

module.exports = router;
