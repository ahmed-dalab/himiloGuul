const { Router } = require("express");
const { login, registerUser } = require("../controllers/userController");

const router = Router();

// public route
// login route
router.post("/login", login);
// register route
router.post("/register", registerUser);

module.exports = router;
