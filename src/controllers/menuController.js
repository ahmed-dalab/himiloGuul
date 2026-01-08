const Menu = require("../models/Menu");

// Create menu item
const createMenu = async (req, res) => {
  try {
    const { name, path, parentId } = req.body;

    // Validate required fields
    if (!name || !path) {
      return res.status(400).json({
        message: "Name and path are required fields",
      });
    }

    // If parentId is provided, validate it exists
    if (parentId) {
      const parentMenu = await Menu.findById(parentId);
      if (!parentMenu) {
        return res.status(404).json({
          message: "Parent menu not found",
        });
      }
    }

    const menu = new Menu({
      name,
      path,
      parentId: parentId || null,
    });

    await menu.save();

    res.status(201).json({
      message: "Menu created successfully",
      menu,
    });
  } catch (error) {
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
};

// Get all menu items (optionally filter by parentId)
const getAllMenus = async (req, res) => {
  try {
    const { parentId } = req.query;
    let query = {};

    // If parentId is provided, filter by it; otherwise get root items (null parentId)
    if (parentId !== undefined) {
      if (parentId === "null" || parentId === "") {
        query.parentId = null;
      } else {
        query.parentId = parentId;
      }
    }

    const menus = await Menu.find(query).populate("parentId", "name path");

    res.status(200).json({
      message: "Menus retrieved successfully",
      menus,
    });
  } catch (error) {
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
};

// Get menu item by ID
const getMenuById = async (req, res) => {
  try {
    const { id } = req.params;

    const menu = await Menu.findById(id).populate("parentId", "name path");

    if (!menu) {
      return res.status(404).json({
        message: "Menu not found",
      });
    }

    res.status(200).json({
      message: "Menu retrieved successfully",
      menu,
    });
  } catch (error) {
    if (error.name === "CastError") {
      return res.status(400).json({
        message: "Invalid menu ID",
      });
    }
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
};

// Update menu item
const updateMenu = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, path, parentId } = req.body;

    const menu = await Menu.findById(id);

    if (!menu) {
      return res.status(404).json({
        message: "Menu not found",
      });
    }

    // Validate parentId if provided
    if (parentId !== undefined) {
      if (parentId === null || parentId === "") {
        menu.parentId = null;
      } else {
        // Prevent setting parentId to itself
        if (parentId === id) {
          return res.status(400).json({
            message: "Menu cannot be its own parent",
          });
        }

        const parentMenu = await Menu.findById(parentId);
        if (!parentMenu) {
          return res.status(404).json({
            message: "Parent menu not found",
          });
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

    const updatedMenu = await Menu.findById(id).populate(
      "parentId",
      "name path"
    );

    res.status(200).json({
      message: "Menu updated successfully",
      menu: updatedMenu,
    });
  } catch (error) {
    if (error.name === "CastError") {
      return res.status(400).json({
        message: "Invalid menu ID",
      });
    }
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
};

// Delete menu item
const deleteMenu = async (req, res) => {
  try {
    const { id } = req.params;

    const menu = await Menu.findById(id);

    if (!menu) {
      return res.status(404).json({
        message: "Menu not found",
      });
    }

    // Check if this menu has children
    const children = await Menu.find({ parentId: id });
    if (children.length > 0) {
      return res.status(400).json({
        message:
          "Cannot delete menu item that has children. Please delete or reassign children first.",
        childrenCount: children.length,
      });
    }

    await Menu.findByIdAndDelete(id);

    res.status(200).json({
      message: "Menu deleted successfully",
    });
  } catch (error) {
    if (error.name === "CastError") {
      return res.status(400).json({
        message: "Invalid menu ID",
      });
    }
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
};

module.exports = {
  createMenu,
  getAllMenus,
  getMenuById,
  updateMenu,
  deleteMenu,
};

