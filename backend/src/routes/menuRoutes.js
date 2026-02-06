const { Router } = require("express");
const {
  getMenusForMe,
  createMenu,
  getAllMenus,
  getMenuById,
  updateMenu,
  deleteMenu,
} = require("../controllers/menuController");
const { protect, requirePermission, requireAdminOrPermission, requireSellerOrBuyerOrPermission } = require("../middlewares/authMiddleware");

const router = Router();

router.get("/", getAllMenus);
router.get("/me", protect, requireSellerOrBuyerOrPermission("view_menus_me"), getMenusForMe);
router.get("/:id", getMenuById);
router.post("/", protect, requireAdminOrPermission("manage_menus"), createMenu);
router.put("/:id", protect, requireAdminOrPermission("manage_menus"), updateMenu);
router.delete("/:id", protect, requireAdminOrPermission("manage_menus"), deleteMenu);

module.exports = router;

