const Business = require("../models/Business");
const User = require("../models/User");
const Contact = require("../models/Contact");

// List all businesses (admin only)
const listAllBusinesses = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      status,
      category,
      sortBy = "createdAt",
      sortOrder = "desc",
    } = req.query;

    // Build query
    const query = {};

    if (status) {
      query.status = status;
    }

    if (category) {
      query.category = category;
    }

    // Pagination
    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);
    const skip = (pageNum - 1) * limitNum;

    // Sorting
    const sortOptions = {};
    sortOptions[sortBy] = sortOrder === "asc" ? 1 : -1;

    // Execute query
    const businesses = await Business.find(query)
      .populate("owner", "name email phone")
      .sort(sortOptions)
      .skip(skip)
      .limit(limitNum);

    // Get total count for pagination
    const total = await Business.countDocuments(query);

    res.status(200).json({
      success: true,
      data: businesses,
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

// List pending businesses (admin only)
const listPendingBusinesses = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      sortBy = "createdAt",
      sortOrder = "desc",
    } = req.query;

    // Pagination
    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);
    const skip = (pageNum - 1) * limitNum;

    // Sorting
    const sortOptions = {};
    sortOptions[sortBy] = sortOrder === "asc" ? 1 : -1;

    // Execute query - only pending businesses
    const businesses = await Business.find({ status: "pending" })
      .populate("owner", "name email phone")
      .sort(sortOptions)
      .skip(skip)
      .limit(limitNum);

    // Get total count for pagination
    const total = await Business.countDocuments({ status: "pending" });

    res.status(200).json({
      success: true,
      data: businesses,
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

// Approve business (admin only)
const approveBusiness = async (req, res) => {
  try {
    const { id } = req.params;

    const business = await Business.findById(id);

    if (!business) {
      return res.status(404).json({
        success: false,
        message: "Business not found",
      });
    }

    if (business.status === "approved") {
      return res.status(400).json({
        success: false,
        message: "Business is already approved",
      });
    }

    business.status = "approved";
    await business.save();

    res.status(200).json({
      success: true,
      message: "Business approved successfully",
      data: business,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

// Reject business (admin only)
const rejectBusiness = async (req, res) => {
  try {
    const { id } = req.params;

    const business = await Business.findById(id);

    if (!business) {
      return res.status(404).json({
        success: false,
        message: "Business not found",
      });
    }

    if (business.status === "rejected") {
      return res.status(400).json({
        success: false,
        message: "Business is already rejected",
      });
    }

    business.status = "rejected";
    await business.save();

    res.status(200).json({
      success: true,
      message: "Business rejected successfully",
      data: business,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

// List all users (admin only)
const listAllUsers = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      roleId,
      isBanned,
      sortBy = "createdAt",
      sortOrder = "desc",
      search,
    } = req.query;

    // Build query
    const query = {};

    if (roleId) {
      query.roleId = roleId;
    }

    if (isBanned !== undefined) {
      query.isBanned = isBanned === "true";
    }

    // Search by name or email
    if (search) {
      query.$or = [
        { name: { $regex: search, $options: "i" } },
        { email: { $regex: search, $options: "i" } },
      ];
    }

    // Pagination
    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);
    const skip = (pageNum - 1) * limitNum;

    // Sorting
    const sortOptions = {};
    sortOptions[sortBy] = sortOrder === "asc" ? 1 : -1;

    // Execute query
    const users = await User.find(query)
      .populate("roleId", "name")
      .select("-password")
      .sort(sortOptions)
      .skip(skip)
      .limit(limitNum);

    // Get total count for pagination
    const total = await User.countDocuments(query);

    res.status(200).json({
      success: true,
      data: users,
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

// Ban/unban user (admin only)
const banUnbanUser = async (req, res) => {
  try {
    const { id } = req.params;
    let { isBanned } = req.body;

    // Accept boolean or string "true"/"false"
    if (typeof isBanned === "string") {
      isBanned = isBanned.toLowerCase() === "true";
    }
    if (typeof isBanned !== "boolean") {
      return res.status(400).json({
        success: false,
        message: "isBanned is required and must be a boolean or string 'true'/'false'",
      });
    }

    const user = await User.findById(id);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    // Prevent admin from banning themselves
    if (req.user._id.toString() === id) {
      return res.status(400).json({
        success: false,
        message: "You cannot ban/unban yourself",
      });
    }

    // Prevent banning other admins (optional - you can remove this if you want to allow it)
    // You might want to check if the user being banned is an admin
    // This depends on your business logic

    user.isBanned = isBanned;
    await user.save();

    res.status(200).json({
      success: true,
      message: `User ${isBanned ? "banned" : "unbanned"} successfully`,
      data: user.toJSON(),
    });
  } catch (error) {
    if (error.name === "CastError") {
      return res.status(400).json({
        success: false,
        message: "Invalid user ID",
      });
    }
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

// Delete user (admin only)
const deleteUser = async (req, res) => {
  try {
    const { id } = req.params;

    const user = await User.findById(id);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    // Prevent admin from deleting themselves
    if (req.user._id.toString() === id) {
      return res.status(400).json({
        success: false,
        message: "You cannot delete yourself",
      });
    }

    // Check if user has associated businesses
    const userBusinesses = await Business.find({ owner: id });
    if (userBusinesses.length > 0) {
      return res.status(400).json({
        success: false,
        message:
          "Cannot delete user with associated businesses. Please delete or reassign businesses first.",
        businessesCount: userBusinesses.length,
      });
    }

    await User.findByIdAndDelete(id);

    res.status(200).json({
      success: true,
      message: "User deleted successfully",
    });
  } catch (error) {
    if (error.name === "CastError") {
      return res.status(400).json({
        success: false,
        message: "Invalid user ID",
      });
    }
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

// List all contacts (admin only)
const listAllContacts = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      status,
      sortBy = "createdAt",
      sortOrder = "desc",
    } = req.query;

    // Build query
    const query = {};

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

// Delete contact (admin only)
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
  listAllBusinesses,
  listPendingBusinesses,
  approveBusiness,
  rejectBusiness,
  listAllUsers,
  banUnbanUser,
  deleteUser,
  listAllContacts,
  deleteContact,
};

