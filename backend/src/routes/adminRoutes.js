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
  getDashboardStats,
  getRecentActivity,
} = require("../controllers/adminController");
const { protect, requireAdminOrPermission } = require("../middlewares/authMiddleware");

const router = Router();

router.use(protect);

router.get("/dashboard", requireAdminOrPermission("view_admin_dashboard"), getDashboardStats);
router.get("/activities", requireAdminOrPermission("view_admin_activities"), getRecentActivity);
router.get("/businesses", requireAdminOrPermission("view_admin_business"), listAllBusinesses);
router.get("/businesses/pending", requireAdminOrPermission("view_admin_business"), listPendingBusinesses);
router.put("/businesses/:id/approve", requireAdminOrPermission("manage_business_approval"), approveBusiness);
router.put("/businesses/:id/reject", requireAdminOrPermission("manage_business_approval"), rejectBusiness);
router.get("/users", requireAdminOrPermission("view_admin_users"), listAllUsers);
router.put("/users/:id/ban", requireAdminOrPermission("manage_users"), banUnbanUser);
router.delete("/users/:id", requireAdminOrPermission("manage_users"), deleteUser);
router.get("/contacts", requireAdminOrPermission("manage_contacts"), listAllContacts);

module.exports = router;

