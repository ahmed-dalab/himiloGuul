const { Router } = require("express");
const {
  browseBusinesses,
  getMyBusinesses,
  getBusinessById,
  createBusiness,
  updateBusiness,
  deleteBusiness,
  approveBusiness,
  markBusinessAsSold,
} = require("../controllers/businessController");
const { protect, requirePermission, requireAdminOrPermission, requireSellerOrPermission } = require("../middlewares/authMiddleware");
const { handleMultipleUpload } = require("../middlewares/uploadMiddleware");

const router = Router();

// Public (no auth)
router.get("/", browseBusinesses);

router.get("/my", protect, requireSellerOrPermission("view_seller_my_businesses"), getMyBusinesses);

router.get("/:id", getBusinessById);
router.put("/:id/approve", protect, requireAdminOrPermission("manage_business_approval"), approveBusiness);
router.put("/:id/sold", protect, requireSellerOrPermission("mark_business_sold"), markBusinessAsSold);
router.post("/", protect, requireSellerOrPermission("create_business"), handleMultipleUpload, createBusiness);
router.put("/:id", protect, requireSellerOrPermission("update_business"), handleMultipleUpload, updateBusiness);
router.delete("/:id", protect, requireSellerOrPermission("delete_business"), deleteBusiness);

module.exports = router;
