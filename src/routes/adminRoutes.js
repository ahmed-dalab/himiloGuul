const { Router } = require("express");
const {
  listAllBusinesses,
  listPendingBusinesses,
  approveBusiness,
  rejectBusiness,
} = require("../controllers/adminController");
const { protect, authorize } = require("../middlewares/authMiddleware");

const router = Router();

// All admin routes require authentication and admin role
router.use(protect);
router.use(authorize("admin"));

// Business management routes
router.get("/businesses", listAllBusinesses);
router.get("/businesses/pending", listPendingBusinesses);
router.put("/businesses/:id/approve", approveBusiness);
router.put("/businesses/:id/reject", rejectBusiness);

module.exports = router;

