const multer = require("multer");
const { uploadSingle, uploadMultiple } = require("../controllers/imageController");

// Middleware for handling single image upload
const handleSingleUpload = (req, res, next) => {
  uploadSingle(req, res, (err) => {
    if (err) {
      if (err instanceof multer.MulterError) {
        if (err.code === "LIMIT_FILE_SIZE") {
          return res.status(400).json({
            message: "File too large. Maximum size is 5MB",
          });
        }
        return res.status(400).json({
          message: `Upload error: ${err.message}`,
        });
      }
      return res.status(400).json({
        message: err.message || "Error uploading file",
      });
    }
    next();
  });
};

// Middleware for handling multiple image uploads
const handleMultipleUpload = (req, res, next) => {
  uploadMultiple(req, res, (err) => {
    if (err) {
      if (err instanceof multer.MulterError) {
        if (err.code === "LIMIT_FILE_SIZE") {
          return res.status(400).json({
            message: "One or more files are too large. Maximum size is 5MB per file",
          });
        }
        if (err.code === "LIMIT_FILE_COUNT") {
          return res.status(400).json({
            message: "Too many files. Maximum is 10 files",
          });
        }
        return res.status(400).json({
          message: `Upload error: ${err.message}`,
        });
      }
      return res.status(400).json({
        message: err.message || "Error uploading files",
      });
    }
    next();
  });
};

module.exports = {
  handleSingleUpload,
  handleMultipleUpload,
};

