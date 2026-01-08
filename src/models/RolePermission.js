const mongoose = require("mongoose");

const rolePermissionSchema = new mongoose.Schema(
  {
    roleId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Role",
      required: true,
    },
    permissionId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Permission",
      required: true,
    },
  },
  { timestamps: true }
);

// Add compound unique index to prevent duplicate role-permission pairs
rolePermissionSchema.index({ roleId: 1, permissionId: 1 }, { unique: true });

// Add indexes for better query performance
rolePermissionSchema.index({ roleId: 1 });
rolePermissionSchema.index({ permissionId: 1 });

const RolePermission = mongoose.model("RolePermission", rolePermissionSchema);

module.exports = RolePermission;
