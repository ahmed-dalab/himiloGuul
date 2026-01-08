const { Router } = require("express");
const {
  getAllUsers,
  deleteUser,
  banOrUnbanUser,
} = require("../controllers/userController");
const { protect, authorize } = require("../middlewares/authMiddleware");

const router = Router();

// GET /api/admin/users - List all users
router.get("/users", protect, authorize("admin"), getAllUsers);

// PUT /api/admin/users/:id/ban - Ban/unban user
router.put("/users/:id/ban", protect, authorize("admin"), banOrUnbanUser);

// DELETE /api/admin/users/:id - Delete user
router.delete("/users/:id", protect, authorize("admin"), deleteUser);

module.exports = router;

