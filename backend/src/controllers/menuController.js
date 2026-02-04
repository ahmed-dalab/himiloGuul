const Menu = require("../models/Menu");
const RolePermission = require("../models/RolePermission");
const Permission = require("../models/Permission");
const MenuPermission = require("../models/MenuPermission");

/**
 * GET /api/menus/me - Get menus for the current user (permission-driven).
 * Returns only menus that the user has at least one permission for (via their role).
 * Uses MenuPermission (permission → menu links); falls back to Permission.menuId if no MenuPermission entries.
 * No role-based hardcoding: admin sees only menus they have permissions for.
 */
const getMenusForMe = async (req, res) => {
  try {
    const user = req.user;
    if (!user) {
      return res.status(401).json({ message: "Not authenticated" });
    }

    if (!user.roleId) {
      return res.status(200).json({
        message: "Menus retrieved successfully",
        count: 0,
        menus: [],
      });
    }

    const roleId = user.roleId._id || user.roleId;
    const rolePermissions = await RolePermission.find({ roleId }).select("permissionId");
    const permissionIds = [...new Set(rolePermissions.map((rp) => rp.permissionId.toString()))];
    if (permissionIds.length === 0) {
      return res.status(200).json({
        message: "Menus retrieved successfully",
        count: 0,
        menus: [],
      });
    }

    let menuIds = [];
    const menuPermissions = await MenuPermission.find({
      permissionId: { $in: permissionIds },
    }).select("menuId");
    if (menuPermissions.length > 0) {
      menuIds = [...new Set(menuPermissions.map((mp) => mp.menuId.toString()))];
    } else {
      const permissions = await Permission.find({ _id: { $in: permissionIds } }).select("menuId");
      const withMenu = permissions.filter((p) => p.menuId);
      menuIds = [...new Set(withMenu.map((p) => p.menuId.toString()))];
    }

    if (menuIds.length === 0) {
      return res.status(200).json({
        message: "Menus retrieved successfully",
        count: 0,
        menus: [],
      });
    }

    const menus = await Menu.find({ _id: { $in: menuIds } })
      .populate("parentId", "name path")
      .sort({ createdAt: -1 });

    res.status(200).json({
      message: "Menus retrieved successfully",
      count: menus.length,
      menus,
    });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

// POST /api/menus - Create a new menu
const createMenu = async (req, res) => {
  try {
    const { name, path, parentId } = req.body;

    // Validate required fields
    if (!name || !path) {
      return res
        .status(400)
        .json({ message: "Name and path are required fields" });
    }

    // If parentId is provided, validate it exists
    if (parentId) {
      const parentMenu = await Menu.findById(parentId);
      if (!parentMenu) {
        return res.status(404).json({ message: "Parent menu not found" });
      }
    }

    const menu = new Menu({
      name,
      path,
      parentId: parentId || null,
    });

    await menu.save();

    // Populate parentId if it exists
    await menu.populate("parentId", "name path");

    res.status(201).json({
      message: "Menu created successfully",
      menu,
    });
  } catch (error) {
    if (error.name === "ValidationError") {
      return res.status(400).json({
        message: "Validation error",
        error: error.message,
      });
    }
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

// GET /api/menus - Get all menus
const getAllMenus = async (req, res) => {
  try {
    const { parentId } = req.query;

    let query = {};
    if (parentId === "null" || parentId === null) {
      query.parentId = null;
    } else if (parentId) {
      query.parentId = parentId;
    }

    const menus = await Menu.find(query)
      .populate("parentId", "name path")
      .sort({ createdAt: -1 });

    res.status(200).json({
      message: "Menus retrieved successfully",
      count: menus.length,
      menus,
    });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

// GET /api/menus/:id - Get menu by ID
const getMenuById = async (req, res) => {
  try {
    const { id } = req.params;

    const menu = await Menu.findById(id).populate("parentId", "name path");

    if (!menu) {
      return res.status(404).json({ message: "Menu not found" });
    }

    res.status(200).json({
      message: "Menu retrieved successfully",
      menu,
    });
  } catch (error) {
    if (error.name === "CastError") {
      return res.status(400).json({ message: "Invalid menu ID" });
    }
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

// PUT /api/menus/:id - Update menu
const updateMenu = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, path, parentId } = req.body;

    const menu = await Menu.findById(id);

    if (!menu) {
      return res.status(404).json({ message: "Menu not found" });
    }

    // Validate parentId if provided
    if (parentId !== undefined) {
      if (parentId === null || parentId === "null") {
        menu.parentId = null;
      } else {
        // Prevent setting parentId to itself
        if (parentId === id) {
          return res
            .status(400)
            .json({ message: "Menu cannot be its own parent" });
        }

        const parentMenu = await Menu.findById(parentId);
        if (!parentMenu) {
          return res.status(404).json({ message: "Parent menu not found" });
        }

        // Prevent circular references (check if parentId is a descendant)
        const checkCircular = async (menuId, targetParentId) => {
          const currentMenu = await Menu.findById(menuId);
          if (!currentMenu || !currentMenu.parentId) return false;
          if (currentMenu.parentId.toString() === targetParentId) return true;
          return checkCircular(currentMenu.parentId, targetParentId);
        };

        const isCircular = await checkCircular(parentId, id);
        if (isCircular) {
          return res
            .status(400)
            .json({ message: "Circular reference detected" });
        }

        menu.parentId = parentId;
      }
    }

    // Update other fields
    if (name !== undefined) {
      menu.name = name;
    }
    if (path !== undefined) {
      menu.path = path;
    }

    await menu.save();
    await menu.populate("parentId", "name path");

    res.status(200).json({
      message: "Menu updated successfully",
      menu,
    });
  } catch (error) {
    if (error.name === "CastError") {
      return res.status(400).json({ message: "Invalid menu ID" });
    }
    if (error.name === "ValidationError") {
      return res.status(400).json({
        message: "Validation error",
        error: error.message,
      });
    }
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

// DELETE /api/menus/:id - Delete menu
const deleteMenu = async (req, res) => {
  try {
    const { id } = req.params;

    const menu = await Menu.findById(id);

    if (!menu) {
      return res.status(404).json({ message: "Menu not found" });
    }

    // Check if menu has children
    const children = await Menu.find({ parentId: id });
    if (children.length > 0) {
      return res.status(400).json({
        message:
          "Cannot delete menu with child menus. Please delete or reassign child menus first.",
        childrenCount: children.length,
      });
    }

    await Menu.findByIdAndDelete(id);

    res.status(200).json({
      message: "Menu deleted successfully",
    });
  } catch (error) {
    if (error.name === "CastError") {
      return res.status(400).json({ message: "Invalid menu ID" });
    }
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

module.exports = {
  getMenusForMe,
  createMenu,
  getAllMenus,
  getMenuById,
  updateMenu,
  deleteMenu,
};

