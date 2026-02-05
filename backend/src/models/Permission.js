const mongoose = require("mongoose");

/**
 * Permission: each permission belongs to exactly one menu (menuId).
 * A user sees a menu if their role has at least one permission whose menuId is that menu
 * (via RolePermission: Role -> Permission).
 */
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
