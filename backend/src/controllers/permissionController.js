const Permission = require("../models/Permission");
const Menu = require("../models/Menu");

/**
 * Create a new permission
 */
const createPermission = async (req, res) => {
  try {
    const { name, menuId } = req.body;

    if (!name) {
      return res.status(400).json({
        success: false,
        message: "Name is required",
      });
    }

    if (!menuId) {
      return res.status(400).json({
        success: false,
        message: "menuId is required; each permission belongs to one menu",
      });
    }

    const menu = await Menu.findById(menuId);
    if (!menu) {
      return res.status(404).json({
        success: false,
        message: "Menu not found",
      });
    }

    const existingPermission = await Permission.findOne({ name });
    if (existingPermission) {
      return res.status(409).json({
        success: false,
        message: "Permission with this name already exists",
      });
    }

    const permission = await Permission.create({ name, menuId });

    // Populate menu details
    await permission.populate("menuId", "name path");

    res.status(201).json({
      success: true,
      message: "Permission created successfully",
      data: permission,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to create permission",
      error: error.message,
    });
  }
};

/**
 * Get all permissions with optional filters
 */
const getAllPermissions = async (req, res) => {
  try {
    const { menuId, page = 1, limit = 10 } = req.query;

    // Build query
    const query = {};
    if (menuId) {
      query.menuId = menuId;
    }

    // Pagination
    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);
    const skip = (pageNum - 1) * limitNum;

    // Execute query
    const permissions = await Permission.find(query)
      .populate("menuId", "name path parentId")
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limitNum);

    // Get total count
    const total = await Permission.countDocuments(query);

    res.status(200).json({
      success: true,
      data: permissions,
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
      message: "Failed to fetch permissions",
      error: error.message,
    });
  }
};

/**
 * Get permission by ID
 */
const getPermissionById = async (req, res) => {
  try {
    const { id } = req.params;

    const permission = await Permission.findById(id).populate(
      "menuId",
      "name path parentId"
    );

    if (!permission) {
      return res.status(404).json({
        success: false,
        message: "Permission not found",
      });
    }

    res.status(200).json({
      success: true,
      data: permission,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to fetch permission",
      error: error.message,
    });
  }
};

/**
 * Update permission
 */
const updatePermission = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, menuId } = req.body;

    const permission = await Permission.findById(id);

    if (!permission) {
      return res.status(404).json({
        success: false,
        message: "Permission not found",
      });
    }

    // menuId is required; verify menu exists if provided
    if (menuId !== undefined) {
      if (!menuId) {
        return res.status(400).json({
          success: false,
          message: "menuId is required; each permission belongs to one menu",
        });
      }
      const menu = await Menu.findById(menuId);
      if (!menu) {
        return res.status(404).json({
          success: false,
          message: "Menu not found",
        });
      }
      permission.menuId = menuId;
    }

    // Check if name is being changed and if it already exists
    if (name && name !== permission.name) {
      const existingPermission = await Permission.findOne({ name });
      if (existingPermission) {
        return res.status(409).json({
          success: false,
          message: "Permission with this name already exists",
        });
      }
      permission.name = name;
    }

    await permission.save();
    await permission.populate("menuId", "name path parentId");

    res.status(200).json({
      success: true,
      message: "Permission updated successfully",
      data: permission,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to update permission",
      error: error.message,
    });
  }
};

/**
 * Delete permission
 */
const deletePermission = async (req, res) => {
  try {
    const { id } = req.params;

    const permission = await Permission.findById(id);

    if (!permission) {
      return res.status(404).json({
        success: false,
        message: "Permission not found",
      });
    }

    await Permission.findByIdAndDelete(id);

    res.status(200).json({
      success: true,
      message: "Permission deleted successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to delete permission",
      error: error.message,
    });
  }
};

module.exports = {
  createPermission,
  getAllPermissions,
  getPermissionById,
  updatePermission,
  deletePermission,
};
