const cloudinary = require("../lib/cloudinary");
const multer = require("multer");
const { Readable } = require("stream");

// Configure multer to use memory storage
const storage = multer.memoryStorage();

// File filter for image validation
const fileFilter = (req, file, cb) => {
  // Accept only image files
  if (file.mimetype.startsWith("image/")) {
    cb(null, true);
  } else {
    cb(new Error("Only image files are allowed"), false);
  }
};

// Configure multer
const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  },
});

// Middleware for single image upload
const uploadSingle = upload.single("image");

// Middleware for multiple image uploads
const uploadMultiple = upload.array("images", 10); // Max 10 images

// Upload single image to Cloudinary
const uploadImage = async (file) => {
  return new Promise((resolve, reject) => {
    const uploadStream = cloudinary.uploader.upload_stream(
      {
        resource_type: "image",
        folder: "himilo-guul", // Optional: organize images in a folder
      },
      (error, result) => {
        if (error) {
          reject(error);
        } else {
          resolve({
            url: result.secure_url,
            publicId: result.public_id,
          });
        }
      }
    );

    // Convert buffer to stream
    const stream = Readable.from(file.buffer);
    stream.pipe(uploadStream);
  });
};

// Upload multiple images to Cloudinary
const uploadImages = async (files) => {
  try {
    const uploadPromises = files.map((file) => uploadImage(file));
    const results = await Promise.all(uploadPromises);
    return results;
  } catch (error) {
    throw new Error(`Error uploading images: ${error.message}`);
  }
};

// Delete image from Cloudinary
const deleteImage = async (publicId) => {
  try {
    const result = await cloudinary.uploader.destroy(publicId);
    return result;
  } catch (error) {
    throw new Error(`Error deleting image: ${error.message}`);
  }
};

// Delete multiple images from Cloudinary
const deleteImages = async (publicIds) => {
  try {
    const deletePromises = publicIds.map((publicId) => deleteImage(publicId));
    const results = await Promise.all(deletePromises);
    return results;
  } catch (error) {
    throw new Error(`Error deleting images: ${error.message}`);
  }
};

module.exports = {
  uploadSingle,
  uploadMultiple,
  uploadImage,
  uploadImages,
  deleteImage,
  deleteImages,
};

