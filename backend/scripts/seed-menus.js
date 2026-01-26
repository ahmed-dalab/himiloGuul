/**
 * Seed default menus. Run: node scripts/seed-menus.js
 * Requires: MONGO_URI in .env (or set before running)
 * 
 * Creates:
 * - Bottom navigation menus: home, business, deals, profile
 * - Drawer menus: users, roles, menus, permissions, settings
 */

require("dotenv").config();
const mongoose = require("mongoose");
const Menu = require("../src/models/Menu");

// Bottom navigation bar menus (no parent)
const BOTTOM_NAV_MENUS = [
  { name: "Home", path: "/" },
  { name: "Business", path: "/business" },
  { name: "Deals", path: "/deals" },
  { name: "Profile", path: "/profile" },
];

// Drawer menus (no parent)
const DRAWER_MENUS = [
  { name: "Users", path: "/admin/users" },
  { name: "Roles", path: "/admin/roles" },
  { name: "Menus", path: "/admin/menus" },
  { name: "Permissions", path: "/admin/permissions" },
  { name: "Settings", path: "/admin/settings" },
];

async function seedMenus() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log("✓ MongoDB connected\n");

    console.log("=== Seeding Menus ===\n");
    
    // Seed bottom navigation menus
    console.log("  Bottom Navigation Menus:");
    for (const menu of BOTTOM_NAV_MENUS) {
      const exists = await Menu.findOne({ path: menu.path });
      if (exists) {
        console.log(`    ✓ Menu "${menu.name}" (${menu.path}) already exists`);
      } else {
        await Menu.create({
          name: menu.name,
          path: menu.path,
          parentId: null,
        });
        console.log(`    ✓ Created menu "${menu.name}" (${menu.path})`);
      }
    }

    // Seed drawer menus
    console.log("\n  Drawer Menus:");
    for (const menu of DRAWER_MENUS) {
      const exists = await Menu.findOne({ path: menu.path });
      if (exists) {
        console.log(`    ✓ Menu "${menu.name}" (${menu.path}) already exists`);
      } else {
        await Menu.create({
          name: menu.name,
          path: menu.path,
          parentId: null,
        });
        console.log(`    ✓ Created menu "${menu.name}" (${menu.path})`);
      }
    }

    console.log("\n✓ Menus seeding completed successfully!");
  } catch (e) {
    console.error("\n✗ Error during seeding:", e);
    process.exit(1);
  } finally {
    await mongoose.disconnect();
    console.log("\n✓ MongoDB disconnected");
  }
}

seedMenus();
