const { Router } = require("express");
const {
  getMenusForMe,
  createMenu,
  getAllMenus,
  getMenuById,
  updateMenu,
  deleteMenu,
} = require("../controllers/menuController");
const { protect, requireAdminOrPermission } = require("../middlewares/authMiddleware");

const router = Router();

// GET /api/menus - Get all menus (with optional parentId query) - public
router.get("/", getAllMenus);

// GET /api/menus/me - Get menus for current user (filtered by role permissions) - requires auth
router.get("/me", protect, getMenusForMe);

// GET /api/menus/:id - Get menu by ID - public
router.get("/:id", getMenuById);

// POST /api/menus - Create menu: admin OR permission "manage_menus"
router.post("/", protect, requireAdminOrPermission("manage_menus"), createMenu);

// PUT /api/menus/:id - Update menu: admin OR permission "manage_menus"
router.put("/:id", protect, requireAdminOrPermission("manage_menus"), updateMenu);

// DELETE /api/menus/:id - Delete menu: admin OR permission "manage_menus"
router.delete("/:id", protect, requireAdminOrPermission("manage_menus"), deleteMenu);

module.exports = router;

