const { Router } = require("express");
const {
  createContact,
  getMyContacts,
  getContactById,
  updateContact,
  deleteContact,
} = require("../controllers/contactController");
const { protect, authorize } = require("../middlewares/authMiddleware");

const router = Router();

// All contact routes require authentication
router.use(protect);

// Create contact (buyers can create)
router.post("/", authorize("buyer", "seller", "admin"), createContact);

// Get my contacts (buyer or seller can view their contacts)
router.get("/my", authorize("buyer", "seller", "admin"), getMyContacts);

// Get contact details by ID
router.get("/:id", authorize("buyer", "seller", "admin"), getContactById);

// Update contact (buyer or seller can update)
router.put("/:id", authorize("buyer", "seller", "admin"), updateContact);

// Delete contact (buyer or seller can delete)
router.delete("/:id", authorize("buyer", "seller", "admin"), deleteContact);

module.exports = router;
