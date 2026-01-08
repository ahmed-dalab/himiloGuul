const Role = require("../models/Role");

// Create a new role (admin only)
const createRole = async (req, res) => {
  try {
    const { name } = req.body;

    // Validate input
    if (!name || name.trim() === "") {
      return res.status(400).json({
        success: false,
        message: "Role name is required",
      });
    }

    // Check if role already exists
    const existingRole = await Role.findOne({
      name: name.trim().toLowerCase(),
    });

    if (existingRole) {
      return res.status(409).json({
        success: false,
        message: "Role with this name already exists",
      });
    }

    // Create role
    const role = await Role.create({
      name: name.trim().toLowerCase(),
    });

    res.status(201).json({
      success: true,
      message: "Role created successfully",
      data: role,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

// Get all roles (admin only)
const getAllRoles = async (req, res) => {
  try {
    const roles = await Role.find().sort({ name: 1 });

    res.status(200).json({
      success: true,
      data: roles,
      count: roles.length,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

// Get role by ID (admin only)
const getRoleById = async (req, res) => {
  try {
    const { id } = req.params;

    const role = await Role.findById(id);

    if (!role) {
      return res.status(404).json({
        success: false,
        message: "Role not found",
      });
    }

    res.status(200).json({
      success: true,
      data: role,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

// Update role (admin only)
const updateRole = async (req, res) => {
  try {
    const { id } = req.params;
    const { name } = req.body;

    // Validate input
    if (!name || name.trim() === "") {
      return res.status(400).json({
        success: false,
        message: "Role name is required",
      });
    }

    const role = await Role.findById(id);

    if (!role) {
      return res.status(404).json({
        success: false,
        message: "Role not found",
      });
    }

    // Check if another role with the same name exists
    const existingRole = await Role.findOne({
      name: name.trim().toLowerCase(),
      _id: { $ne: id },
    });

    if (existingRole) {
      return res.status(409).json({
        success: false,
        message: "Role with this name already exists",
      });
    }

    // Update role
    role.name = name.trim().toLowerCase();
    await role.save();

    res.status(200).json({
      success: true,
      message: "Role updated successfully",
      data: role,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

// Delete role (admin only)
const deleteRole = async (req, res) => {
  try {
    const { id } = req.params;

    const role = await Role.findById(id);

    if (!role) {
      return res.status(404).json({
        success: false,
        message: "Role not found",
      });
    }

    // Check if any users are using this role
    const User = require("../models/User");
    const usersWithRole = await User.countDocuments({ roleId: id });

    if (usersWithRole > 0) {
      return res.status(400).json({
        success: false,
        message: `Cannot delete role. ${usersWithRole} user(s) are currently using this role`,
      });
    }

    await Role.findByIdAndDelete(id);

    res.status(200).json({
      success: true,
      message: "Role deleted successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

module.exports = {
  createRole,
  getAllRoles,
  getRoleById,
  updateRole,
  deleteRole,
};

