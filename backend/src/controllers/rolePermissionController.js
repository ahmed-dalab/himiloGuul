const RolePermission = require("../models/RolePermission");
const Role = require("../models/Role");
const Permission = require("../models/Permission");

/**
 * Create a new role-permission assignment
 */
const createRolePermission = async (req, res) => {
  try {
    const { roleId, permissionId } = req.body;

    // Validate required fields
    if (!roleId || !permissionId) {
      return res.status(400).json({
        success: false,
        message: "roleId and permissionId are required fields",
      });
    }

    // Verify role exists
    const role = await Role.findById(roleId);
    if (!role) {
      return res.status(404).json({
        success: false,
        message: "Role not found",
      });
    }

    // Verify permission exists
    const permission = await Permission.findById(permissionId);
    if (!permission) {
      return res.status(404).json({
        success: false,
        message: "Permission not found",
      });
    }

    // Check if role-permission assignment already exists
    const existingRolePermission = await RolePermission.findOne({
      roleId,
      permissionId,
    });
    if (existingRolePermission) {
      return res.status(409).json({
        success: false,
        message: "This role-permission assignment already exists",
      });
    }

    // Create role-permission assignment
    const rolePermission = await RolePermission.create({ roleId, permissionId });

    // Populate role and permission details
    await rolePermission.populate("roleId", "name");
    await rolePermission.populate("permissionId", "name menuId");

    res.status(201).json({
      success: true,
      message: "Role-permission assignment created successfully",
      data: rolePermission,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to create role-permission assignment",
      error: error.message,
    });
  }
};

/**
 * Get all role-permission assignments with optional filters
 */
const getAllRolePermissions = async (req, res) => {
  try {
    const { roleId, permissionId, page = 1, limit = 10 } = req.query;

    // Build query
    const query = {};
    if (roleId) query.roleId = roleId;
    if (permissionId) query.permissionId = permissionId;

    // Pagination
    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);
    const skip = (pageNum - 1) * limitNum;

    // Execute query
    const rolePermissions = await RolePermission.find(query)
      .populate("roleId", "name")
      .populate("permissionId", "name menuId")
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limitNum);

    // Get total count
    const total = await RolePermission.countDocuments(query);

    res.status(200).json({
      success: true,
      data: rolePermissions,
      pagination: {
        page: pageNum,
        limit: limitNum,
        total,
        pages: Math.ceil(total / limitNum),
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to fetch role-permission assignments",
      error: error.message,
    });
  }
};

/**
 * Get role-permission assignment by ID
 */
const getRolePermissionById = async (req, res) => {
  try {
    const { id } = req.params;

    const rolePermission = await RolePermission.findById(id)
      .populate("roleId", "name")
      .populate("permissionId", "name menuId");

    if (!rolePermission) {
      return res.status(404).json({
        success: false,
        message: "Role-permission assignment not found",
      });
    }

    res.status(200).json({
      success: true,
      data: rolePermission,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to fetch role-permission assignment",
      error: error.message,
    });
  }
};

/**
 * Get permissions for a specific role
 */
const getPermissionsByRole = async (req, res) => {
  try {
    const { roleId } = req.params;

    // Verify role exists
    const role = await Role.findById(roleId);
    if (!role) {
      return res.status(404).json({
        success: false,
        message: "Role not found",
      });
    }

    // Get all permissions for this role
    const rolePermissions = await RolePermission.find({ roleId })
      .populate("permissionId", "name menuId")
      .populate("permissionId.menuId", "name path");

    const permissions = rolePermissions.map((rp) => rp.permissionId);

    res.status(200).json({
      success: true,
      data: {
        role: {
          _id: role._id,
          name: role.name,
        },
        permissions,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to fetch permissions for role",
      error: error.message,
    });
  }
};

/**
 * Get roles for a specific permission
 */
const getRolesByPermission = async (req, res) => {
  try {
    const { permissionId } = req.params;

    // Verify permission exists
    const permission = await Permission.findById(permissionId);
    if (!permission) {
      return res.status(404).json({
        success: false,
        message: "Permission not found",
      });
    }

    // Get all roles for this permission
    const rolePermissions = await RolePermission.find({ permissionId })
      .populate("roleId", "name");

    const roles = rolePermissions.map((rp) => rp.roleId);

    res.status(200).json({
      success: true,
      data: {
        permission: {
          _id: permission._id,
          name: permission.name,
        },
        roles,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to fetch roles for permission",
      error: error.message,
    });
  }
};

/**
 * Update role-permission assignment
 */
const updateRolePermission = async (req, res) => {
  try {
    const { id } = req.params;
    const { roleId, permissionId } = req.body;

    const rolePermission = await RolePermission.findById(id);

    if (!rolePermission) {
      return res.status(404).json({
        success: false,
        message: "Role-permission assignment not found",
      });
    }

    // Verify role exists if roleId is being updated
    if (roleId) {
      const role = await Role.findById(roleId);
      if (!role) {
        return res.status(404).json({
          success: false,
          message: "Role not found",
        });
      }
      rolePermission.roleId = roleId;
    }

    // Verify permission exists if permissionId is being updated
    if (permissionId) {
      const permission = await Permission.findById(permissionId);
      if (!permission) {
        return res.status(404).json({
          success: false,
          message: "Permission not found",
        });
      }
      rolePermission.permissionId = permissionId;
    }

    // Check if the new combination already exists
    const existingRolePermission = await RolePermission.findOne({
      roleId: rolePermission.roleId,
      permissionId: rolePermission.permissionId,
      _id: { $ne: id },
    });
    if (existingRolePermission) {
      return res.status(409).json({
        success: false,
        message: "This role-permission assignment already exists",
      });
    }

    await rolePermission.save();
    await rolePermission.populate("roleId", "name");
    await rolePermission.populate("permissionId", "name menuId");

    res.status(200).json({
      success: true,
      message: "Role-permission assignment updated successfully",
      data: rolePermission,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to update role-permission assignment",
      error: error.message,
    });
  }
};

/**
 * Delete role-permission assignment
 */
const deleteRolePermission = async (req, res) => {
  try {
    const { id } = req.params;

    const rolePermission = await RolePermission.findById(id);

    if (!rolePermission) {
      return res.status(404).json({
        success: false,
        message: "Role-permission assignment not found",
      });
    }

    await RolePermission.findByIdAndDelete(id);

    res.status(200).json({
      success: true,
      message: "Role-permission assignment deleted successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to delete role-permission assignment",
      error: error.message,
    });
  }
};

/**
 * Delete role-permission assignment by roleId and permissionId
 */
const deleteRolePermissionByRoleAndPermission = async (req, res) => {
  try {
    const { roleId, permissionId } = req.params;

    const rolePermission = await RolePermission.findOne({ roleId, permissionId });

    if (!rolePermission) {
      return res.status(404).json({
        success: false,
        message: "Role-permission assignment not found",
      });
    }

    await RolePermission.findByIdAndDelete(rolePermission._id);

    res.status(200).json({
      success: true,
      message: "Role-permission assignment deleted successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to delete role-permission assignment",
      error: error.message,
    });
  }
};

module.exports = {
  createRolePermission,
  getAllRolePermissions,
  getRolePermissionById,
  getPermissionsByRole,
  getRolesByPermission,
  updateRolePermission,
  deleteRolePermission,
  deleteRolePermissionByRoleAndPermission,
};
