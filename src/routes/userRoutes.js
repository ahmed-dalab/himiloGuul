const { Router } = require("express");
const {
  getAllUsers,
  getUserById,
  getUserProfile,
  login,
  registerUser,
  updateUser,
  deleteUser,
} = require("../controllers/userController");

const router = Router();

// get all users (only admin can access)
router.get("/", getAllUsers);
// get user by id (only admin and the user himself can access)
router.get("/:id", getUserById);
// get user profile (authenticated users)
router.get("/profile", getUserProfile);
// update user (only the user himself can access)
router.put("/:id", updateUser);
// delete user (only admin and the user himself can access)
router.delete("/:id", deleteUser);

// public route
// login route
router.post("/login", login);
// register route
router.post("/register", registerUser);
module.exports = router;
