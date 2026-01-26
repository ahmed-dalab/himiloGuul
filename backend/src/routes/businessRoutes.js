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
const { authorize, protect } = require("../middlewares/authMiddleware");
const { handleMultipleUpload } = require("../middlewares/uploadMiddleware");

const router = Router();

// Browse businesses (public endpoint - no auth required)
router.get("/", browseBusinesses);
// Get my businesses (seller/owner only) - must be before /:id
router.get("/my", protect, authorize("seller", "admin"), getMyBusinesses);
// Business by id: public for approved; owner/admin for any status
router.get("/:id", getBusinessById);

// Approve business (admin only)
router.put("/:id/approve", protect, authorize("admin"), approveBusiness);
// Mark as sold (owner or admin)
router.put("/:id/sold", protect, authorize("seller", "admin"), markBusinessAsSold);

// create business (sellers/owners can create)
router.post(
  "/",
  protect,
  authorize("seller", "admin"),
  handleMultipleUpload,
  createBusiness,
);

// update business (only business owner or admin can access)
router.put(
  "/:id",
  protect,
  authorize("seller", "admin"),
  handleMultipleUpload,
  updateBusiness,
);

// delete business (only admin and the business owner can access)
router.delete("/:id", protect, authorize("seller", "admin"), deleteBusiness);

module.exports = router;
