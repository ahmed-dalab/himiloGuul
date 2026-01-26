const Business = require("../models/Business");

// Browse businesses with filters, pagination, and sorting (public endpoint)
const browseBusinesses = async (req, res) => {
  try {
    const {
      category,
      location,
      minPrice,
      maxPrice,
      search,
      page = 1,
      limit = 10,
      sortBy = "createdAt",
      sortOrder = "desc",
    } = req.query;

    // Build query
    const query = {};

    // Only show approved businesses for public browsing
    query.status = "approved";
    query.isSold = false;

    // Filter by category
    if (category) {
      query.category = category;
    }

    // Filter by location
    if (location) {
      query.location = { $regex: location, $options: "i" };
    }

    // Filter by price range
    if (minPrice || maxPrice) {
      query.askingPrice = {};
      if (minPrice) {
        query.askingPrice.$gte = Number(minPrice);
      }
      if (maxPrice) {
        query.askingPrice.$lte = Number(maxPrice);
      }
    }

    // Search by name or description
    if (search) {
      query.$or = [
        { name: { $regex: search, $options: "i" } },
        { description: { $regex: search, $options: "i" } },
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
// Get my businesses (seller/owner only)
const getMyBusinesses = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      status,
      sortBy = "createdAt",
      sortOrder = "desc",
    } = req.query;

    // Build query - only businesses owned by the current user
    const query = { owner: req.user._id };

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

// get business by id (public for approved, owner/admin for any status)
const getBusinessById = async (req, res) => {
  try {
    const { id } = req.params;

    const business = await Business.findById(id).populate(
      "owner",
      "name email phone",
    );

    if (!business) {
      return res.status(404).json({
        success: false,
        message: "Business not found",
      });
    }

    // Check if user is authenticated
    if (req.user) {
      // Check if user is admin or owner
      const isAdmin = req.user.role === "admin";
      const isOwner = business.owner._id.toString() === req.user._id.toString();

      // Owners and admins can view any status
      if (isAdmin || isOwner) {
        return res.status(200).json({
          success: true,
          data: business,
        });
      }
    }

    // Public and authenticated users can only view approved and unsold businesses
    if (business.status !== "approved" || business.isSold) {
      return res.status(403).json({
        success: false,
        message: "Access denied. This business is not available for viewing",
      });
    }

    res.status(200).json({
      success: true,
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

// create business (sellers/owners can create)
const createBusiness = async (req, res) => {
  try {
    const {
      name,
      address,
      phone,
      email,
      website,
      description,
      category,
      askingPrice,
      location,
    } = req.body;

    // Validate required fields
    if (!name || !address || !phone || !email) {
      return res.status(400).json({
        success: false,
        message: "Name, address, phone, and email are required",
      });
    }

    // Check if email already exists
    const existingBusiness = await Business.findOne({ email });
    if (existingBusiness) {
      return res.status(409).json({
        success: false,
        message: "Business with this email already exists",
      });
    }

    // Handle image uploads if provided
    let images = [];
    if (req.files && req.files.length > 0) {
      const { uploadImages } = require("./imageController");
      images = await uploadImages(req.files);
    }

    // Create business
    const business = await Business.create({
      name,
      address,
      phone,
      email,
      website,
      description,
      category,
      askingPrice: askingPrice ? Number(askingPrice) : undefined,
      location,
      owner: req.user._id,
      images,
      status: "pending", // New businesses start as pending
    });

    // Populate owner info
    await business.populate("owner", "name email phone");

    res.status(201).json({
      success: true,
      message: "Business created successfully. Waiting for admin approval.",
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

// update business (only business owner or admin can access)
const updateBusiness = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      name,
      address,
      phone,
      email,
      website,
      description,
      category,
      askingPrice,
      location,
    } = req.body;

    const business = await Business.findById(id);

    if (!business) {
      return res.status(404).json({
        success: false,
        message: "Business not found",
      });
    }

    // Check if user is admin or owner
    const isAdmin = req.user.role === "admin";
    const isOwner = business.owner.toString() === req.user._id.toString();

    if (!isAdmin && !isOwner) {
      return res.status(403).json({
        success: false,
        message: "Access denied. You can only update your own businesses",
      });
    }

    // Check if email is being changed and if it already exists
    if (email && email !== business.email) {
      const existingBusiness = await Business.findOne({ email });
      if (existingBusiness) {
        return res.status(409).json({
          success: false,
          message: "Business with this email already exists",
        });
      }
    }

    // Handle new image uploads if provided
    let newImages = [];
    if (req.files && req.files.length > 0) {
      const { uploadImages } = require("./imageController");
      newImages = await uploadImages(req.files);
    }

    // Update business fields
    if (name) business.name = name;
    if (address) business.address = address;
    if (phone) business.phone = phone;
    if (email) business.email = email;
    if (website !== undefined) business.website = website;
    if (description !== undefined) business.description = description;
    if (category) business.category = category;
    if (askingPrice !== undefined) business.askingPrice = Number(askingPrice);
    if (location !== undefined) business.location = location;

    // Add new images to existing ones
    if (newImages.length > 0) {
      business.images = [...business.images, ...newImages];
    }

    // If owner updates, set status back to pending for admin review
    if (!isAdmin && business.status === "approved") {
      business.status = "pending";
    }

    await business.save();
    await business.populate("owner", "name email phone");

    res.status(200).json({
      success: true,
      message: isAdmin
        ? "Business updated successfully"
        : "Business updated successfully. Changes are pending admin approval.",
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
// delete business (only admin and the business owner can access)
const deleteBusiness = async (req, res) => {
  try {
    const { id } = req.params;
    const business = await Business.findById(id);

    if (!business) {
      return res.status(404).json({
        success: false,
        message: "Business not found",
      });
    }

    // Check if user is admin or owner
    const isAdmin = req.user.role === "admin";
    const isOwner = business.owner.toString() === req.user._id.toString();

    if (!isAdmin && !isOwner) {
      return res.status(403).json({
        success: false,
        message: "Access denied. You can only delete your own businesses",
      });
    }

    // Delete images from Cloudinary if they exist
    if (business.images && business.images.length > 0) {
      const { deleteImages } = require("./imageController");
      const publicIds = business.images
        .map((img) => img.publicId)
        .filter((id) => id);
      if (publicIds.length > 0) {
        try {
          await deleteImages(publicIds);
        } catch (error) {
          console.error("Error deleting images from Cloudinary:", error);
          // Continue with business deletion even if image deletion fails
        }
      }
    }

    await Business.findByIdAndDelete(id);

    res.status(200).json({
      success: true,
      message: "Business deleted successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

// PUT /api/business/:id/sold - Mark business as sold (owner or admin)
const markBusinessAsSold = async (req, res) => {
  try {
    const { id } = req.params;
    const { isSold } = req.body;

    const business = await Business.findById(id);

    if (!business) {
      return res.status(404).json({
        success: false,
        message: "Business not found",
      });
    }

    const isAdmin = req.user.role === "admin";
    const isOwner = business.owner.toString() === req.user._id.toString();

    if (!isAdmin && !isOwner) {
      return res.status(403).json({
        success: false,
        message: "Access denied. Only the owner or admin can mark as sold",
      });
    }

    business.isSold = isSold === true || isSold === "true";
    await business.save();
    await business.populate("owner", "name email phone");

    res.status(200).json({
      success: true,
      message: `Business ${business.isSold ? "marked as sold" : "marked as available"}`,
      data: business,
    });
  } catch (error) {
    if (error.name === "CastError") {
      return res.status(400).json({ success: false, message: "Invalid business ID" });
    }
    res.status(500).json({ success: false, message: "Server error", error: error.message });
  }
};

// PUT /api/business/:id/approve - Approve business (admin only)
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

    // Populate owner for response
    await business.populate("owner", "name email phone");

    res.status(200).json({
      success: true,
      message: "Business approved successfully",
      data: business,
    });
  } catch (error) {
    if (error.name === "CastError") {
      return res.status(400).json({
        success: false,
        message: "Invalid business ID",
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
  browseBusinesses,
  getMyBusinesses,
  getBusinessById,
  createBusiness,
  updateBusiness,
  deleteBusiness,
  approveBusiness,
  markBusinessAsSold,
};
