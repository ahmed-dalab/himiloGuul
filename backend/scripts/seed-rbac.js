/**
 * RBAC Seed: Role-Based Access Control with permission-driven menu visibility.
 * Run: node scripts/seed-rbac.js
 * Requires: MONGO_URI in .env
 *
 * Rules:
 * - Users have one role. Roles have multiple permissions (via RolePermission).
 * - Menus are not assigned to users or roles. Each menu is linked to one or more permissions (via MenuPermission).
 * - A user sees a menu if and only if they have at least one permission associated with that menu.
 *
 * Creates:
 * - Roles: admin, seller (if not exist)
 * - Admin user: ali@gmail.com / admin123 (if not exist)
 * - Menus: seller (Home, My Business, Contacts, Profile) + admin (Home, Business, Users, Roles, Permissions, Role Permissions, Menus, Settings)
 * - Permissions: view_home, view_business, view_contacts, view_profile, manage_users, manage_roles, manage_permissions, manage_role_permissions, manage_menus, manage_settings
 * - MenuPermission: links each permission to the relevant menu(s)
 * - RolePermission: seller gets view_*; admin gets all permissions
 */

require("dotenv").config();
const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");
const Role = require("../src/models/Role");
const User = require("../src/models/User");
const Menu = require("../src/models/Menu");
const Permission = require("../src/models/Permission");
const RolePermission = require("../src/models/RolePermission");
const MenuPermission = require("../src/models/MenuPermission");

const ADMIN_EMAIL = "ali@gmail.com";
const ADMIN_PASSWORD = "admin123";
const SELLER_EMAIL = "seller@example.com";
const SELLER_PASSWORD = "seller123";
const ADMIN_ROLE_NAME = "admin";
const SELLER_ROLE_NAME = "seller";

// All menus: seller portal + admin portal (path must be unique)
const SEED_MENUS = [
  // Seller portal
  { name: "Home", path: "/seller/dashboard" },
  { name: "My Business", path: "/seller/my-businesses" },
  { name: "Contacts", path: "/seller/contacts" },
  { name: "Profile", path: "/seller/profile" },
  // Admin portal
  { name: "Home", path: "/admin" },
  { name: "Business", path: "/admin/business" },
  { name: "Users", path: "/admin/users" },
  { name: "Roles", path: "/admin/roles" },
  { name: "Permissions", path: "/admin/permissions" },
  { name: "Role Permissions", path: "/admin/role-permissions" },
  { name: "Menus", path: "/admin/menus" },
  { name: "Settings", path: "/admin/settings" },
  { name: "Profile", path: "/admin/profile" },
];

// Permission names (standardized)
const VIEW_PERMISSIONS = ["view_home", "view_business", "view_contacts", "view_profile"];
const MANAGE_PERMISSIONS = [
  "manage_users",
  "manage_roles",
  "manage_permissions",
  "manage_role_permissions",
  "manage_menus",
  "manage_settings",
];

// Permission name -> menu paths (this permission unlocks these menus)
const PERMISSION_TO_MENU_PATHS = {
  view_home: ["/seller/dashboard", "/admin"],
  view_business: ["/seller/my-businesses", "/admin/business"],
  view_contacts: ["/seller/contacts"],
  view_profile: ["/seller/profile", "/admin/profile"],
  manage_users: ["/admin/users"],
  manage_roles: ["/admin/roles"],
  manage_permissions: ["/admin/permissions"],
  manage_role_permissions: ["/admin/role-permissions"],
  manage_menus: ["/admin/menus"],
  manage_settings: ["/admin/settings"],
};

async function seed() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log("✓ MongoDB connected\n");

    // 1. Roles
    console.log("=== Roles ===");
    let adminRole = await Role.findOne({ name: ADMIN_ROLE_NAME });
    if (!adminRole) {
      adminRole = await Role.create({ name: ADMIN_ROLE_NAME });
      console.log(`  ✓ Created role "${ADMIN_ROLE_NAME}"`);
    } else {
      console.log(`  ✓ Role "${ADMIN_ROLE_NAME}" already exists`);
    }
    let sellerRole = await Role.findOne({ name: SELLER_ROLE_NAME });
    if (!sellerRole) {
      sellerRole = await Role.create({ name: SELLER_ROLE_NAME });
      console.log(`  ✓ Created role "${SELLER_ROLE_NAME}"`);
    } else {
      console.log(`  ✓ Role "${SELLER_ROLE_NAME}" already exists`);
    }

    // 2. Admin user
    console.log("\n=== Admin User ===");
    const existingUser = await User.findOne({ email: ADMIN_EMAIL });
    if (existingUser) {
      if (existingUser.roleId?.toString() !== adminRole._id.toString()) {
        existingUser.roleId = adminRole._id;
        await existingUser.save();
        console.log(`  ✓ Updated user role to admin`);
      } else {
        console.log(`  ✓ User ${ADMIN_EMAIL} already exists`);
      }
    } else {
      const hashedPassword = await bcrypt.hash(ADMIN_PASSWORD, 10);
      await User.create({
        name: "Admin",
        email: ADMIN_EMAIL,
        password: hashedPassword,
        roleId: adminRole._id,
      });
      console.log(`  ✓ Created user ${ADMIN_EMAIL} (password: ${ADMIN_PASSWORD})`);
    }

    // 2b. Seller test user (for manual testing)
    console.log("\n=== Seller Test User ===");
    const existingSeller = await User.findOne({ email: SELLER_EMAIL });
    if (existingSeller) {
      if (existingSeller.roleId?.toString() !== sellerRole._id.toString()) {
        existingSeller.roleId = sellerRole._id;
        await existingSeller.save();
        console.log(`  ✓ Updated user role to seller`);
      } else {
        console.log(`  ✓ User ${SELLER_EMAIL} already exists`);
      }
    } else {
      const hashedSellerPassword = await bcrypt.hash(SELLER_PASSWORD, 10);
      await User.create({
        name: "Test Seller",
        email: SELLER_EMAIL,
        password: hashedSellerPassword,
        roleId: sellerRole._id,
      });
      console.log(`  ✓ Created user ${SELLER_EMAIL} (password: ${SELLER_PASSWORD})`);
    }

    // 3. Menus (by path)
    console.log("\n=== Menus ===");
    const menuByPath = {};
    for (const menu of SEED_MENUS) {
      let m = await Menu.findOne({ path: menu.path });
      if (!m) {
        m = await Menu.create({ name: menu.name, path: menu.path, parentId: null });
        console.log(`  ✓ Created menu "${menu.name}" (${menu.path})`);
      } else {
        console.log(`  ✓ Menu "${menu.name}" (${menu.path}) already exists`);
      }
      menuByPath[menu.path] = m;
    }

    // 4. Permissions (no required menuId; links via MenuPermission)
    console.log("\n=== Permissions ===");
    const permissionByName = {};
    const allPermissionNames = [...VIEW_PERMISSIONS, ...MANAGE_PERMISSIONS];
    for (const name of allPermissionNames) {
      let p = await Permission.findOne({ name });
      if (!p) {
        const firstPath = PERMISSION_TO_MENU_PATHS[name]?.[0];
        const primaryMenuId = firstPath ? menuByPath[firstPath]?._id : null;
        p = await Permission.create({ name, menuId: primaryMenuId || undefined });
        console.log(`  ✓ Created permission "${name}"`);
      } else {
        console.log(`  ✓ Permission "${name}" already exists`);
      }
      permissionByName[name] = p;
    }

    // 5. MenuPermission: link each permission to its menu(s)
    console.log("\n=== Menu-Permission Links ===");
    for (const [permName, paths] of Object.entries(PERMISSION_TO_MENU_PATHS)) {
      const p = permissionByName[permName];
      if (!p) continue;
      for (const path of paths) {
        const menu = menuByPath[path];
        if (!menu) continue;
        const exists = await MenuPermission.findOne({
          menuId: menu._id,
          permissionId: p._id,
        });
        if (!exists) {
          await MenuPermission.create({ menuId: menu._id, permissionId: p._id });
          console.log(`  ✓ Linked "${permName}" → "${menu.name}" (${path})`);
        }
      }
    }

    // 6. RolePermission: seller gets view_*; admin gets all
    console.log("\n=== Role Permissions ===");
    for (const name of allPermissionNames) {
      const p = permissionByName[name];
      if (!p) continue;

      const assignToSeller = VIEW_PERMISSIONS.includes(name);
      const assignToAdmin = true;

      if (assignToSeller) {
        const existsSeller = await RolePermission.findOne({
          roleId: sellerRole._id,
          permissionId: p._id,
        });
        if (!existsSeller) {
          await RolePermission.create({ roleId: sellerRole._id, permissionId: p._id });
          console.log(`  ✓ Assigned "${name}" to seller`);
        }
      }
      if (assignToAdmin) {
        const existsAdmin = await RolePermission.findOne({
          roleId: adminRole._id,
          permissionId: p._id,
        });
        if (!existsAdmin) {
          await RolePermission.create({ roleId: adminRole._id, permissionId: p._id });
          console.log(`  ✓ Assigned "${name}" to admin`);
        }
      }
    }

    console.log("\n✓ RBAC seed completed successfully!");
    console.log("\nSeller sees: Home, My Business, Contacts, Profile (permission-driven).");
    console.log("Admin sees: all menus (permission-driven; admin has all permissions).");
    console.log("Menus without permission are hidden. Backend APIs still enforce permission checks.");
  } catch (e) {
    console.error("\n✗ Error during seeding:", e);
    process.exit(1);
  } finally {
    await mongoose.disconnect();
    console.log("\n✓ MongoDB disconnected");
  }
}

seed();
