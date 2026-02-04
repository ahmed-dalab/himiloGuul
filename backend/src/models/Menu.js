const mongoose = require("mongoose");

const menuSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },
    path: {
      type: String,
      required: true,
      trim: true,
    },
    parentId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Menu",
      default: null,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    icon: {
      type: String,
      trim: true,
      default: null,
    },
  },
  { timestamps: true }
);

// Add indexes for better query performance
menuSchema.index({ parentId: 1 });
menuSchema.index({ path: 1 });

const Menu = mongoose.model("Menu", menuSchema);

module.exports = Menu;
