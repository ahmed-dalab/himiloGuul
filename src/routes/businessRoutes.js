const { Router } = require("express");
const {
  getAllBusinesses,
  getBusinessById,
  createBusiness,
  updateBusiness,
  deleteBusiness,
} = require("../controllers/businessController");

const router = Router();
// get all businesses (only admin can access)
router.get("/", getAllBusinesses);
// get business by id (only admin and the business owner can access)
router.get("/:id", getBusinessById);
// create business (authenticated users)
router.post("/", createBusiness);
// update business (only business owner can access)
router.put("/:id", updateBusiness);
// delete business (only admin and the business owner can access)
router.delete("/:id", deleteBusiness);
module.exports = router;
