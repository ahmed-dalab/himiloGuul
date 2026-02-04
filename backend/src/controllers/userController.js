const User = require("../models/User");
const Role = require("../models/Role");
const Business = require("../models/Business");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");

// helper to create JWT access token
const generateToken = (userId) => {
  return jwt.sign({ id: userId }, process.env.JWT_SECRET, { expiresIn: "1d" });
};

//  register user
const registerUser = async (req, res) => {
  try {
    const { name, email, password, phone, location, profilePicture, role } =
      req.body;

    if (!name || !email || !password || !role) {
      return res
        .status(400)
        .json({ message: "Name, email, password and role are required" });
    }

    if (password.length < 6) {
      return res
        .status(400)
        .json({ message: "Password must be at least 6 characters" });
    }

    // Check if email already registered
    const existing = await User.findOne({ email });
    if (existing) {
      return res.status(409).json({ message: "Email already in use" });
    }

    // If a role name is provided, validate it exists BEFORE creating user
    // This ensures we don't create a user with an invalid role
    let roleDoc = null;
    if (role) {
      roleDoc = await Role.findOne({
        name: { $regex: `^${role}$`, $options: "i" },
      });
      if (!roleDoc) {
        return res.status(400).json({ message: "Role not found" });
      }
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Build user object - only include roleId if role was found
    const userData = {
      name,
      email,
      password: hashedPassword,
      phone,
      location,
      profilePicture,
    };

    // Only add roleId if roleDoc exists
    if (roleDoc) {
      userData.roleId = roleDoc._id;
    }

    const user = new User(userData);

    await user.save();

    // Verify roleId was saved (re-fetch to ensure it's persisted)
    const savedUser = await User.findById(user._id);

    // populate role name for backward compatibility
    if (roleDoc) {
      await savedUser.populate("roleId", "name");
      savedUser.role = savedUser.roleId ? savedUser.roleId.name : null;
    }

    const token = generateToken(savedUser._id);

    res.status(201).json({
      message: "User registered successfully",
      token,
      user: savedUser.toJSON(),
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(409).json({ message: "Email already exists" });
    }
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

//  login user
const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res
        .status(400)
        .json({ message: "Email and password are required" });
    }

    // populate role name so response includes role info
    const user = await User.findOne({ email }).populate("roleId", "name");

    if (!user) {
      return res.status(401).json({ message: "Invalid credentials" });
    }

    if (user.isBanned) {
      return res.status(403).json({ message: "User is banned" });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ message: "Invalid credentials" });
    }

    // Add role name for backward compatibility
    if (user.roleId) {
      user.role = user.roleId.name;
    }

    const token = generateToken(user._id);

    res
      .status(200)
      .json({ message: "User logged in", token, user: user.toJSON() });
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
        message:
          "Invalid updates. Allowed fields: name, phone, location, profilePicture",
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

// GET /api/users - Get all users (only admin can access)
const getAllUsers = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      roleId,
      role: roleName,
      isBanned,
      sortBy = "createdAt",
      sortOrder = "desc",
      search,
    } = req.query;

    // Build query
    const query = {};

    if (roleId) {
      query.roleId = roleId;
    } else if (roleName) {
      // Filter by role name (e.g. ?role=seller)
      const roleDoc = await Role.findOne({
        name: { $regex: `^${String(roleName).trim()}$`, $options: "i" },
      });
      if (roleDoc) {
        query.roleId = roleDoc._id;
      }
    }

    if (isBanned !== undefined) {
      query.isBanned = isBanned === "true";
    }

    // Search by name or email
    if (search) {
      query.$or = [
        { name: { $regex: search, $options: "i" } },
        { email: { $regex: search, $options: "i" } },
      ];
    }

    // Pagination
    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);
    const skip = (pageNum - 1) * limitNum;

    // Sorting
    const sortOptions = {};
    sortOptions[sortBy] = sortOrder === "asc" ? 1 : -1;

    // Execute query
    const users = await User.find(query)
      .populate("roleId", "name")
      .select("-password")
      .sort(sortOptions)
      .skip(skip)
      .limit(limitNum);

    // Get total count for pagination
    const total = await User.countDocuments(query);

    res.status(200).json({
      message: "Users retrieved successfully",
      data: users,
      pagination: {
        page: pageNum,
        limit: limitNum,
        total,
        pages: Math.ceil(total / limitNum),
      },
    });
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
        message:
          "Access denied. You can only update your own profile or be an admin",
      });
    }

    const user = await User.findById(id);

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    // Define allowed updates based on role (self cannot change role, email, isBanned)
    let allowedUpdates;
    if (req.user.role === "admin") {
      allowedUpdates = [
        "name",
        "email",
        "role",
        "phone",
        "location",
        "profilePicture",
        "isBanned",
      ];
    } else {
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

    // Handle "role" separately: resolve role name to roleId (admin only)
    if (updates.includes("role") && req.user.role === "admin" && req.body.role) {
      const roleDoc = await Role.findOne({
        name: { $regex: `^${String(req.body.role).trim()}$`, $options: "i" },
      });
      if (!roleDoc) {
        return res.status(400).json({ message: "Role not found" });
      }
      user.roleId = roleDoc._id;
    }

    // Update other fields (skip "role" - it is not a schema field; we set roleId above)
    updates.forEach((update) => {
      if (update === "role") return;
      if (req.body[update] !== undefined) {
        user[update] = req.body[update];
      }
    });

    await user.save();
    await user.populate("roleId", "name");
    if (user.roleId) user.role = user.roleId.name;

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

// DELETE /api/users/:id - Delete user (admin and the user himself can access)
const deleteUser = async (req, res) => {
  try {
    const { id } = req.params;

    if (!req.user) {
      return res.status(401).json({ message: "Not authenticated" });
    }

    // Check if user is deleting themselves or is an admin
    const isSelf = req.user._id.toString() === id;
    const isAdmin = req.user.role === "admin";

    if (!isSelf && !isAdmin) {
      return res.status(403).json({
        message:
          "Access denied. You can only delete your own account or be an admin",
      });
    }

    const user = await User.findById(id);

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    // Prevent admin from deleting themselves
    // if (isAdmin && isSelf) {
    //   return res.status(400).json({
    //     message: "You cannot delete yourself",
    //   });
    // }

    // Check if user has associated businesses
    const userBusinesses = await Business.find({ owner: id });
    if (userBusinesses.length > 0) {
      return res.status(400).json({
        message:
          "Cannot delete user with associated businesses. Please delete or reassign businesses first.",
        businessesCount: userBusinesses.length,
      });
    }

    await User.findByIdAndDelete(id);

    res.status(200).json({
      message: "User deleted successfully",
    });
  } catch (error) {
    if (error.name === "CastError") {
      return res.status(400).json({ message: "Invalid user ID" });
    }
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
