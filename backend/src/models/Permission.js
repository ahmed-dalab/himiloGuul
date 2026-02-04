const mongoose = require("mongoose");

const permissionSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
      unique: true,
    },
    // Optional "primary" menu for display in admin UI. Menu visibility is driven by MenuPermission.
    menuId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Menu",
      required: false,
    },
  },
  { timestamps: true }
);

// Add indexes for better query performance
permissionSchema.index({ menuId: 1 });
permissionSchema.index({ name: 1 });

const Permission = mongoose.model("Permission", permissionSchema);

module.exports = Permission;
