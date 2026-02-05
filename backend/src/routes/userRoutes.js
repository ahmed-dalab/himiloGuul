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
const { protect, requireAdminOrPermission } = require("../middlewares/authMiddleware");

const router = Router();

// Protected routes (authentication required)
// Note: /profile routes must come before /:id routes to avoid route conflicts

// POST /api/users - Create user and assign role (admin only; requires manage_users)
router.post("/", protect, requireAdminOrPermission("manage_users"), createUser);

// GET /api/users/profile - Get current user profile
router.get("/profile", protect, getUserProfile);

// PUT /api/users/profile - Update own profile
router.put("/profile", protect, updateUserProfile);

// GET /api/users - List users (admin only; must be before /:id)
router.get("/", protect, requireAdminOrPermission("manage_users"), getAllUsers);

// GET /api/users/:id - Get user public info
router.get("/:id", getUserById);

// PUT /api/users/:id - Update user (self or admin)
router.put("/:id", protect, updateUser);

// DELETE /api/users/:id - Delete user (admin and the user himself can access)
router.delete("/:id", protect, deleteUser);

module.exports = router;
