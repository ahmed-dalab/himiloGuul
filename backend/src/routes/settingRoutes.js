const { Router } = require("express");
const { getSettings, updateSettings } = require("../controllers/settingController");
const { protect, requireAdminOrPermission } = require("../middlewares/authMiddleware");

const router = Router();

// GET /api/settings - Get app settings (admin or manage_settings)
router.get("/", protect, requireAdminOrPermission("manage_settings"), getSettings);

// PUT /api/settings - Update app settings (admin or manage_settings)
router.put("/", protect, requireAdminOrPermission("manage_settings"), updateSettings);

module.exports = router;
