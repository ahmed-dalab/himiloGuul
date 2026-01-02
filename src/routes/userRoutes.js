const { Router } = require("express");
const {
  getAllUsers,
  getUserById,
  getUserProfile,
  updateUserProfile,
  login,
  registerUser,
  updateUser,
  deleteUser,
} = require("../controllers/userController");
const { protect, authorize } = require("../middlewares/authMiddleware");

const router = Router();

// Public routes (no authentication required)
router.post("/register", registerUser);
router.post("/login", login);

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

// GET /api/users - Get all users (only admin can access)
router.get("/", protect, authorize("admin"), getAllUsers);

module.exports = router;
