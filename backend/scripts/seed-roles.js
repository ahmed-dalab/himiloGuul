/**
 * Seed default roles and menus. Run: node scripts/seed-roles.js
 * Requires: MONGO_URI in .env (or set before running)
 * 
 * Creates:
 * - 3 roles: admin, seller, buyer
 * - Bottom navigation menus: home, business, deals, profile
 * - Drawer menus: users, roles, menus, permissions, settings
 */

require("dotenv").config();
const mongoose = require("mongoose");
const Role = require("../src/models/Role");
const Menu = require("../src/models/Menu");

// Only 3 roles: admin, seller, buyer
const ROLES = ["admin", "seller", "buyer"];

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

async function seedRoles() {
  console.log("\n=== Seeding Roles ===");
  for (const name of ROLES) {
    const exists = await Role.findOne({ name: name.toLowerCase() });
    if (exists) {
      console.log(`  ✓ Role "${name}" already exists`);
    } else {
      await Role.create({ name: name.toLowerCase() });
      console.log(`  ✓ Created role "${name}"`);
    }
  }
}

async function seedMenus() {
  console.log("\n=== Seeding Menus ===");
  
  // Seed bottom navigation menus
  console.log("\n  Bottom Navigation Menus:");
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
}

async function seed() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log("✓ MongoDB connected\n");

    await seedRoles();
    await seedMenus();

    console.log("\n✓ Seed completed successfully!");
  } catch (e) {
    console.error("\n✗ Error during seeding:", e);
    process.exit(1);
  } finally {
    await mongoose.disconnect();
    console.log("\n✓ MongoDB disconnected");
  }
}

seed();
