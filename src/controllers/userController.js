const User = require("../models/User");

//  register user
const registerUser = async (req, res) => {
  try {
    res.status(201).json({ message: "User registered" });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

//  login user
const login = async (req, res) => {
  try {
    res.status(200).json({ message: "User logged in" });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

// GET /api/users/profile - Get current user profile
const getUserProfile = async (req, res) => {
  try {
    // req.user is set by the protect middleware
    if (!req.user) {
      return res.status(401).json({ message: "Not authenticated" });
    }

    res.status(200).json({
      message: "User profile retrieved successfully",
      user: req.user.toJSON(),
    });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

// PUT /api/users/profile - Update own profile
const updateUserProfile = async (req, res) => {
  try {
    if (!req.user) {
      return res.status(401).json({ message: "Not authenticated" });
    }

    const allowedUpdates = ["name", "phone", "location", "profilePicture"];
    const updates = Object.keys(req.body);
    const isValidOperation = updates.every((update) =>
      allowedUpdates.includes(update)
    );

    if (!isValidOperation) {
      return res.status(400).json({
        message: "Invalid updates. Allowed fields: name, phone, location, profilePicture",
      });
    }

    // Update user fields
    updates.forEach((update) => {
      if (req.body[update] !== undefined) {
        req.user[update] = req.body[update];
      }
    });

    await req.user.save();

    res.status(200).json({
      message: "Profile updated successfully",
      user: req.user.toJSON(),
    });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

//  get all users
const getAllUsers = async (req, res) => {
  try {
    res.status(200).json({ message: "Get all users" });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

// GET /api/users/:id - Get user public info
const getUserById = async (req, res) => {
  try {
    const { id } = req.params;

    const user = await User.findById(id);

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    // Return public user info (password is already excluded by toJSON method)
    res.status(200).json({
      message: "User retrieved successfully",
      user: user.toJSON(),
    });
  } catch (error) {
    if (error.name === "CastError") {
      return res.status(400).json({ message: "Invalid user ID" });
    }
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

// PUT /api/users/:id - Update user (self or admin)
const updateUser = async (req, res) => {
  try {
    const { id } = req.params;

    if (!req.user) {
      return res.status(401).json({ message: "Not authenticated" });
    }

    // Check if user is updating themselves or is an admin
    if (req.user._id.toString() !== id && req.user.role !== "admin") {
      return res.status(403).json({
        message: "Access denied. You can only update your own profile or be an admin",
      });
    }

    const user = await User.findById(id);

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    // Define allowed updates based on role
    let allowedUpdates;
    if (req.user.role === "admin") {
      // Admin can update all fields except password (password should be updated separately)
      allowedUpdates = ["name", "email", "phone", "location", "profilePicture", "role", "isBanned"];
    } else {
      // Users can only update their own basic profile fields
      allowedUpdates = ["name", "phone", "location", "profilePicture"];
    }

    const updates = Object.keys(req.body);
    const isValidOperation = updates.every((update) =>
      allowedUpdates.includes(update)
    );

    if (!isValidOperation) {
      return res.status(400).json({
        message: `Invalid updates. Allowed fields: ${allowedUpdates.join(", ")}`,
      });
    }

    // Update user fields
    updates.forEach((update) => {
      if (req.body[update] !== undefined) {
        user[update] = req.body[update];
      }
    });

    await user.save();

    res.status(200).json({
      message: "User updated successfully",
      user: user.toJSON(),
    });
  } catch (error) {
    if (error.name === "CastError") {
      return res.status(400).json({ message: "Invalid user ID" });
    }
    if (error.code === 11000) {
      return res.status(409).json({ message: "Email already exists" });
    }
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

//  delete user
const deleteUser = async (req, res) => {
  try {
    res.status(200).json({ message: "Delete user" });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

module.exports = {
  registerUser,
  login,
  getUserProfile,
  updateUserProfile,
  getAllUsers,
  getUserById,
  updateUser,
  deleteUser,
};
