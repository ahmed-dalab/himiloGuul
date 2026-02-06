const { Router } = require("express");
const { getSettings, updateSettings } = require("../controllers/settingController");
const { protect, requireAdminOrPermission } = require("../middlewares/authMiddleware");

const router = Router();

router.get("/", protect, requireAdminOrPermission("manage_settings"), getSettings);
router.put("/", protect, requireAdminOrPermission("manage_settings"), updateSettings);

module.exports = router;
