const { Router } = require("express");
const {
  listAllBusinesses,
  listPendingBusinesses,
  approveBusiness,
  rejectBusiness,
  listAllUsers,
  banUnbanUser,
  deleteUser,
  listAllContacts,
  deleteContact,
  getDashboardStats,
  getRecentActivity,
} = require("../controllers/adminController");
const { protect, authorize } = require("../middlewares/authMiddleware");

const router = Router();

// All admin routes require authentication and admin role
router.use(protect);
router.use(authorize("admin"));

// Dashboard (admin only)
router.get("/dashboard", getDashboardStats);
router.get("/activities", getRecentActivity);

// Business management routes
router.get("/businesses", listAllBusinesses);
router.get("/businesses/pending", listPendingBusinesses);
router.put("/businesses/:id/approve", approveBusiness);
router.put("/businesses/:id/reject", rejectBusiness);

// User management routes
router.get("/users", listAllUsers);
router.put("/users/:id/ban", banUnbanUser);
router.delete("/users/:id", deleteUser);

// Contact management routes
router.get("/contacts", listAllContacts);
router.delete("/contacts/:id", deleteContact);

module.exports = router;

