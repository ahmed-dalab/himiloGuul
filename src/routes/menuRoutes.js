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

// Get all menus (public or protected - adjust as needed)
// Query param: ?parentId=null to get root items, ?parentId=<id> to get children
router.get("/", getAllMenus);

// Get menu by ID
router.get("/:id", getMenuById);

// Create menu (protected - admin only, adjust as needed)
router.post("/", protect, authorize("admin"), createMenu);

// Update menu (protected - admin only, adjust as needed)
router.put("/:id", protect, authorize("admin"), updateMenu);

// Delete menu (protected - admin only, adjust as needed)
router.delete("/:id", protect, authorize("admin"), deleteMenu);

module.exports = router;

