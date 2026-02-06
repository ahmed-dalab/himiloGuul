const { Router } = require("express");
const {
  createContact,
  getMyContacts,
  getContactById,
  updateContact,
  deleteContact,
} = require("../controllers/contactController");
const {
  protect,
  requireSellerOrBuyerOrPermission,
  requireAdminOrSellerOrBuyerOrPermission,
} = require("../middlewares/authMiddleware");

const router = Router();

router.use(protect);

router.post(
  "/",
  requireSellerOrBuyerOrPermission("create_contact"),
  createContact,
);
router.get(
  "/my",
  requireSellerOrBuyerOrPermission("view_my_contacts"),
  getMyContacts,
);
router.get(
  "/:id",
  requireAdminOrSellerOrBuyerOrPermission("view_contact"),
  getContactById,
);
router.put(
  "/:id",
  requireSellerOrBuyerOrPermission("update_contact"),
  updateContact,
);
router.delete(
  "/:id",
  requireSellerOrBuyerOrPermission("delete_contact"),
  deleteContact,
);

module.exports = router;
