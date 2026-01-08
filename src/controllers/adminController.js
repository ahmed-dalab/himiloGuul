const Business = require("../models/Business");

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

module.exports = {
  listAllBusinesses,
  listPendingBusinesses,
  approveBusiness,
  rejectBusiness,
};

