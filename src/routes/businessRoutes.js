const { Router } = require("express");
const {
  getAllBusinesses,
  getBusinessById,
  createBusiness,
  updateBusiness,
  deleteBusiness,
} = require("../controllers/businessController");
const { authorize, protect } = require("../middlewares/authMiddleware");

const router = Router();

// get all businesses (only admin can access)
router.get("/", protect, authorize("admin"), getAllBusinesses);
// get business by id (only admin and the business owner can access)
router.get("/:id", protect, authorize("admin"), getBusinessById);
// create business (authenticated users)
router.post("/", protect, createBusiness);
// update business (only business owner can access)
router.put("/:id", protect, authorize("admin"), updateBusiness);
// delete business (only admin and the business owner can access)
router.delete("/:id", protect, authorize("admin"), deleteBusiness);
module.exports = router;
