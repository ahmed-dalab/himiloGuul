const { Router } = require("express");
const {
  createMenu,
  getAllMenus,
  getMenuById,
  updateMenu,
  deleteMenu,
} = require("../controllers/menuController");
const { protect, authorize } = require("../middlewares/authMiddleware");

const router = Router();

// GET /api/menus - Get all menus (with optional parentId query)
router.get("/", getAllMenus);

// GET /api/menus/:id - Get menu by ID
router.get("/:id", getMenuById);

// POST /api/menus - Create a new menu (protected route)
router.post("/", protect, createMenu);

// PUT /api/menus/:id - Update menu (protected route)
router.put("/:id", protect, updateMenu);

// DELETE /api/menus/:id - Delete menu (protected route)
router.delete("/:id", protect, deleteMenu);

module.exports = router;

