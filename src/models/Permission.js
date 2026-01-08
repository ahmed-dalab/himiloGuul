const mongoose = require("mongoose");

const permissionSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
      unique: true,
    },
    menuId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Menu",
      required: true,
    },
  },
  { timestamps: true }
);

// Add indexes for better query performance
permissionSchema.index({ menuId: 1 });
permissionSchema.index({ name: 1 });

const Permission = mongoose.model("Permission", permissionSchema);

module.exports = Permission;
