/**
 * Seed seller portal: seller role, seller menus, permissions, and role-permissions.
 * Run: node scripts/seed-seller-menus.js
 * Requires: MONGO_URI in .env
 *
 * Creates:
 * - Role: seller (if not exists)
 * - Menus: Home, Business, Profile (bottom nav), Deals (drawer) with seller paths
 * - Permissions: view_seller_dashboard, view_my_businesses, view_seller_profile, view_seller_deals
 * - RolePermission: assign all seller permissions to seller role
 */

require("dotenv").config();
const mongoose = require("mongoose");
const Role = require("../src/models/Role");
const Menu = require("../src/models/Menu");
const Permission = require("../src/models/Permission");
const RolePermission = require("../src/models/RolePermission");

const SELLER_ROLE_NAME = "seller";

// Seller portal menus: paths used by seller layout
const SEED_SELLER_MENUS = [
  { name: "Home", path: "/seller/dashboard" },
  { name: "Business", path: "/seller/my-businesses" },
  { name: "Profile", path: "/seller/profile" },
  { name: "Deals", path: "/seller/deals" },
];

// Permission name -> menu path (permission is linked to that menu)
const SEED_SELLER_PERMISSIONS = [
  { name: "view_seller_dashboard", menuPath: "/seller/dashboard" },
  { name: "view_my_businesses", menuPath: "/seller/my-businesses" },
  { name: "view_seller_profile", menuPath: "/seller/profile" },
  { name: "view_seller_deals", menuPath: "/seller/deals" },
];

async function seed() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log("✓ MongoDB connected\n");

    // 1. Role: seller
    console.log("=== Role ===");
    let sellerRole = await Role.findOne({ name: SELLER_ROLE_NAME });
    if (sellerRole) {
      console.log(`  ✓ Role "${SELLER_ROLE_NAME}" already exists`);
    } else {
      sellerRole = await Role.create({ name: SELLER_ROLE_NAME });
      console.log(`  ✓ Created role "${SELLER_ROLE_NAME}"`);
    }

    // 2. Menus: seller portal (create only if path not exists - paths are unique per portal)
    console.log("\n=== Seller Menus ===");
    const menuByPath = {};
    for (const menu of SEED_SELLER_MENUS) {
      let m = await Menu.findOne({ path: menu.path });
      if (m) {
        console.log(`  ✓ Menu "${menu.name}" (${menu.path}) already exists`);
      } else {
        m = await Menu.create({ name: menu.name, path: menu.path, parentId: null });
        console.log(`  ✓ Created menu "${menu.name}" (${menu.path})`);
      }
      menuByPath[menu.path] = m;
    }

    // 3. Permissions: linked to seller menus
    console.log("\n=== Seller Permissions ===");
    const permissionByName = {};
    for (const perm of SEED_SELLER_PERMISSIONS) {
      const menu = menuByPath[perm.menuPath];
      if (!menu) {
        console.log(`  ✗ Skip permission "${perm.name}": menu ${perm.menuPath} not found`);
        continue;
      }
      let p = await Permission.findOne({ name: perm.name });
      if (p) {
        console.log(`  ✓ Permission "${perm.name}" already exists`);
      } else {
        p = await Permission.create({ name: perm.name, menuId: menu._id });
        console.log(`  ✓ Created permission "${perm.name}" (menu: ${perm.menuPath})`);
      }
      permissionByName[perm.name] = p;
    }

    // 4. RolePermission: assign all seller permissions to seller role
    console.log("\n=== Role Permissions (for seller role) ===");
    for (const perm of SEED_SELLER_PERMISSIONS) {
      const p = permissionByName[perm.name];
      if (!p) continue;
      const exists = await RolePermission.findOne({
        roleId: sellerRole._id,
        permissionId: p._id,
      });
      if (exists) {
        console.log(`  ✓ Seller already has permission "${perm.name}"`);
      } else {
        await RolePermission.create({ roleId: sellerRole._id, permissionId: p._id });
        console.log(`  ✓ Assigned "${perm.name}" to seller role`);
      }
    }

    console.log("\n✓ Seller menus seeding completed successfully!");
    console.log("\nSellers will see only these menus when they log in (via GET /api/menus/me).");
  } catch (e) {
    console.error("\n✗ Error during seeding:", e);
    process.exit(1);
  } finally {
    await mongoose.disconnect();
    console.log("\n✓ MongoDB disconnected");
  }
}

seed();
