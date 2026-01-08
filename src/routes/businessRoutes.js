const { Router } = require("express");
const {
  browseBusinesses,
  getAllBusinesses,
  getMyBusinesses,
  getBusinessById,
  createBusiness,
  updateBusiness,
  deleteBusiness,
} = require("../controllers/businessController");
const { authorize, protect } = require("../middlewares/authMiddleware");
const { handleMultipleUpload } = require("../middlewares/uploadMiddleware");

const router = Router();

// Browse businesses (public endpoint - no auth required)
router.get("/", browseBusinesses);

// Get my businesses (seller/owner only)
router.get("/my", protect, authorize("seller", "admin"), getMyBusinesses);

// get business by id (public for approved businesses)
// Owners can use /my endpoint to view their pending businesses
router.get("/:id", getBusinessById);

// create business (sellers/owners can create)
router.post(
  "/",
  protect,
  authorize("seller", "admin"),
  handleMultipleUpload,
  createBusiness
);

// update business (only business owner or admin can access)
router.put(
  "/:id",
  protect,
  authorize("seller", "admin"),
  handleMultipleUpload,
  updateBusiness
);

// delete business (only admin and the business owner can access)
router.delete("/:id", protect, authorize("seller", "admin"), deleteBusiness);

module.exports = router;
