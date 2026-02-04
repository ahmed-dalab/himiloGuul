const mongoose = require("mongoose");

/**
 * MenuPermission: many-to-many link between Menu and Permission.
 * A menu can be linked to one or more permissions; a permission can unlock one or more menus.
 * A user sees a menu if and only if they have at least one permission associated with that menu
 * (via their role's RolePermission entries).
 */
const menuPermissionSchema = new mongoose.Schema(
  {
    menuId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Menu",
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

menuPermissionSchema.index({ menuId: 1, permissionId: 1 }, { unique: true });
menuPermissionSchema.index({ permissionId: 1 });
menuPermissionSchema.index({ menuId: 1 });

const MenuPermission = mongoose.model("MenuPermission", menuPermissionSchema);

module.exports = MenuPermission;
