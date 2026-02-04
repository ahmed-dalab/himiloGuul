const Contact = require("../models/Contact");
const Business = require("../models/Business");

// Create contact (buyers can create)
const createContact = async (req, res) => {
  try {
    const { sellerRef, businessRef, name, email, phone, message } = req.body;

    // Validate required fields
    if (!sellerRef || !businessRef || !name || !email || !message) {
      return res.status(400).json({
        success: false,
        message: "Seller, business, name, email, and message are required",
      });
    }

    // Validate that business exists
    const business = await Business.findById(businessRef);
    if (!business) {
      return res.status(404).json({
        success: false,
        message: "Business not found",
      });
    }

    // Validate that sellerRef matches the business owner
    if (business.owner.toString() !== sellerRef) {
      return res.status(400).json({
        success: false,
        message: "Seller reference does not match the business owner",
      });
    }

    // Prevent users from contacting themselves
    if (req.user._id.toString() === sellerRef) {
      return res.status(400).json({
        success: false,
        message: "You cannot contact yourself",
      });
    }

    // Check if contact already exists
    const existingContact = await Contact.findOne({
      buyerRef: req.user._id,
      sellerRef,
      businessRef,
    });

    if (existingContact) {
      return res.status(409).json({
        success: false,
        message: "Contact already exists for this buyer-seller-business combination",
        data: existingContact,
      });
    }

    // Create contact
    const contact = await Contact.create({
      buyerRef: req.user._id,
      sellerRef,
      businessRef,
      name: name.trim(),
      email: email.trim(),
      phone: phone ? phone.trim() : undefined,
      message: message.trim(),
      status: "pending",
    });

    // Populate references
    await contact.populate([
      { path: "buyerRef", select: "name email phone" },
      { path: "sellerRef", select: "name email phone" },
      { path: "businessRef", select: "name category askingPrice" },
    ]);

    res.status(201).json({
      success: true,
      message: "Contact created successfully",
      data: contact,
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(409).json({
        success: false,
        message: "Contact already exists for this buyer-seller-business combination",
      });
    }
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

// Get my contacts (buyer or seller can view their contacts)
const getMyContacts = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      status,
      role = "buyer", // 'buyer' or 'seller'
      sortBy = "createdAt",
      sortOrder = "desc",
    } = req.query;

    // Build query based on role
    const query = {};
    if (role === "buyer") {
      query.buyerRef = req.user._id;
    } else if (role === "seller") {
      query.sellerRef = req.user._id;
    } else {
      // If role is not specified, show contacts where user is either buyer or seller
      query.$or = [
        { buyerRef: req.user._id },
        { sellerRef: req.user._id },
      ];
    }

    if (status) {
      query.status = status;
    }

    // Pagination
    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);
    const skip = (pageNum - 1) * limitNum;

    // Sorting
    const sortOptions = {};
    sortOptions[sortBy] = sortOrder === "asc" ? 1 : -1;

    // Execute query
    const contacts = await Contact.find(query)
      .populate("buyerRef", "name email phone")
      .populate("sellerRef", "name email phone")
      .populate("businessRef", "name category askingPrice location")
      .sort(sortOptions)
      .skip(skip)
      .limit(limitNum);

    // Get total count for pagination
    const total = await Contact.countDocuments(query);

    res.status(200).json({
      success: true,
      data: contacts,
      pagination: {
        page: pageNum,
        limit: limitNum,
        total,
        pages: Math.ceil(total / limitNum),
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

// Get contact details by ID
const getContactById = async (req, res) => {
  try {
    const { id } = req.params;

    const contact = await Contact.findById(id)
      .populate("buyerRef", "name email phone")
      .populate("sellerRef", "name email phone")
      .populate("businessRef", "name category askingPrice location description");

    if (!contact) {
      return res.status(404).json({
        success: false,
        message: "Contact not found",
      });
    }

    // Check if user is authorized (must be buyer or seller)
    const isBuyer = contact.buyerRef._id.toString() === req.user._id.toString();
    const isSeller = contact.sellerRef._id.toString() === req.user._id.toString();
    const isAdmin = req.user.role === "admin";

    if (!isBuyer && !isSeller && !isAdmin) {
      return res.status(403).json({
        success: false,
        message: "Access denied. You can only view your own contacts",
      });
    }

    res.status(200).json({
      success: true,
      data: contact,
    });
  } catch (error) {
    if (error.name === "CastError") {
      return res.status(400).json({
        success: false,
        message: "Invalid contact ID",
      });
    }
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

// Update contact (buyer or seller can update)
const updateContact = async (req, res) => {
  try {
    const { id } = req.params;
    const { message, status } = req.body;

    const contact = await Contact.findById(id);

    if (!contact) {
      return res.status(404).json({
        success: false,
        message: "Contact not found",
      });
    }

    // Check if user is authorized (must be buyer or seller)
    const isBuyer = contact.buyerRef.toString() === req.user._id.toString();
    const isSeller = contact.sellerRef.toString() === req.user._id.toString();
    const isAdmin = req.user.role === "admin";

    if (!isBuyer && !isSeller && !isAdmin) {
      return res.status(403).json({
        success: false,
        message: "Access denied. You can only update your own contacts",
      });
    }

    // Update fields
    if (message !== undefined) {
      // Only buyer can update message initially, seller can respond
      if (isBuyer || isAdmin) {
        contact.message = message;
      } else if (isSeller) {
        // Seller can append to message or update status
        contact.message = message;
      }
    }

    if (status !== undefined) {
      // Validate status
      if (!["pending", "responded", "closed"].includes(status)) {
        return res.status(400).json({
          success: false,
          message: "Invalid status. Must be pending, responded, or closed",
        });
      }
      // Both buyer and seller can update status
      contact.status = status;
    }

    await contact.save();

    // Populate references
    await contact.populate([
      { path: "buyerRef", select: "name email phone" },
      { path: "sellerRef", select: "name email phone" },
      { path: "businessRef", select: "name category askingPrice location" },
    ]);

    res.status(200).json({
      success: true,
      message: "Contact updated successfully",
      data: contact,
    });
  } catch (error) {
    if (error.name === "CastError") {
      return res.status(400).json({
        success: false,
        message: "Invalid contact ID",
      });
    }
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

// Delete contact (buyer or seller can delete)
const deleteContact = async (req, res) => {
  try {
    const { id } = req.params;

    const contact = await Contact.findById(id);

    if (!contact) {
      return res.status(404).json({
        success: false,
        message: "Contact not found",
      });
    }

    // Check if user is authorized (must be buyer or seller)
    const isBuyer = contact.buyerRef.toString() === req.user._id.toString();
    const isSeller = contact.sellerRef.toString() === req.user._id.toString();
    const isAdmin = req.user.role === "admin";

    if (!isBuyer && !isSeller && !isAdmin) {
      return res.status(403).json({
        success: false,
        message: "Access denied. You can only delete your own contacts",
      });
    }

    await Contact.findByIdAndDelete(id);

    res.status(200).json({
      success: true,
      message: "Contact deleted successfully",
    });
  } catch (error) {
    if (error.name === "CastError") {
      return res.status(400).json({
        success: false,
        message: "Invalid contact ID",
      });
    }
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

module.exports = {
  createContact,
  getMyContacts,
  getContactById,
  updateContact,
  deleteContact,
};
