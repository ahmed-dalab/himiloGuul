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

// Public routes
// Get all menus (public or protected - adjust as needed)
// Query param: ?parentId=null to get root items, ?parentId=<id> to get children
router.get("/", getAllMenus);

// Get menu by ID
router.get("/:id", getMenuById);

// Protected routes (admin only)
// Apply protect and authorize middleware once for all protected routes
router.use(protect, authorize("admin"));

// Create menu
router.post("/", createMenu);

// Update menu
router.put("/:id", updateMenu);

// Delete menu
router.delete("/:id", deleteMenu);

module.exports = router;

