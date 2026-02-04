/**
 * Seed: admin role, admin user, menus (Home, Menus, Permissions, Roles, Users),
 * permissions for those menus, and assign all permissions to the admin role.
 * Run: node scripts/seed-admin-and-home.js
 * Requires: MONGO_URI in .env
 *
 * Creates:
 * - Role: admin (if not exists)
 * - User: ali@gmail.com / admin123 (hashed), assigned to admin role (if not exists)
 * - Menus: Home, Menus, Permissions, Roles, Users, Role Permissions (so you can create the same on admin portal)
 * - Permissions: manage_menus, manage_permissions, manage_roles, manage_users, manage_role_permissions (linked to menus)
 * - RolePermission: assign all permissions to admin role
 */

require("dotenv").config();
const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");
const Role = require("../src/models/Role");
const User = require("../src/models/User");
const Menu = require("../src/models/Menu");
const Permission = require("../src/models/Permission");
const RolePermission = require("../src/models/RolePermission");

const ADMIN_EMAIL = "ali@gmail.com";
const ADMIN_PASSWORD = "admin123";
const ADMIN_ROLE_NAME = "admin";

// Menus to seed: 4 for bottom nav (Home, Business, Users, Profile) + rest for drawer
const SEED_MENUS = [
  { name: "Home", path: "/" },
  { name: "Business", path: "/business" },
  { name: "Users", path: "/admin/users" },
  { name: "Profile", path: "/profile" },
  { name: "Menus", path: "/admin/menus" },
  { name: "Permissions", path: "/admin/permissions" },
  { name: "Roles", path: "/admin/roles" },
  { name: "Role Permissions", path: "/admin/role-permissions" },
];

// Permission name -> menu path (permission is linked to that menu)
const SEED_PERMISSIONS = [
  { name: "manage_menus", menuPath: "/admin/menus" },
  { name: "manage_permissions", menuPath: "/admin/permissions" },
  { name: "manage_roles", menuPath: "/admin/roles" },
  { name: "manage_users", menuPath: "/admin/users" },
  { name: "manage_role_permissions", menuPath: "/admin/role-permissions" },
];

async function seed() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log("✓ MongoDB connected\n");

    // 1. Role: admin
    console.log("=== Role ===");
    let adminRole = await Role.findOne({ name: ADMIN_ROLE_NAME });
    if (adminRole) {
      console.log(`  ✓ Role "${ADMIN_ROLE_NAME}" already exists`);
    } else {
      adminRole = await Role.create({ name: ADMIN_ROLE_NAME });
      console.log(`  ✓ Created role "${ADMIN_ROLE_NAME}"`);
    }

    // 2. User: ali@gmail.com with hashed password, assigned to admin role
    console.log("\n=== User ===");
    const existingUser = await User.findOne({ email: ADMIN_EMAIL });
    if (existingUser) {
      console.log(`  ✓ User ${ADMIN_EMAIL} already exists`);
      if (existingUser.roleId?.toString() !== adminRole._id.toString()) {
        existingUser.roleId = adminRole._id;
        await existingUser.save();
        console.log(`  ✓ Updated user role to admin`);
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

    // 3. Menus: Home, Menus, Permissions, Roles, Users, Role Permissions
    console.log("\n=== Menus ===");
    const menuByPath = {};
    for (const menu of SEED_MENUS) {
      let m = await Menu.findOne({ path: menu.path });
      if (m) {
        console.log(`  ✓ Menu "${menu.name}" (${menu.path}) already exists`);
      } else {
        m = await Menu.create({ name: menu.name, path: menu.path, parentId: null });
        console.log(`  ✓ Created menu "${menu.name}" (${menu.path})`);
      }
      menuByPath[menu.path] = m;
    }

    // 4. Permissions: linked to menus, for that role
    console.log("\n=== Permissions ===");
    const permissionByName = {};
    for (const perm of SEED_PERMISSIONS) {
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

    // 5. RolePermission: assign all permissions to admin role
    console.log("\n=== Role Permissions (for admin role) ===");
    for (const perm of SEED_PERMISSIONS) {
      const p = permissionByName[perm.name];
      if (!p) continue;
      const exists = await RolePermission.findOne({
        roleId: adminRole._id,
        permissionId: p._id,
      });
      if (exists) {
        console.log(`  ✓ Admin already has permission "${perm.name}"`);
      } else {
        await RolePermission.create({ roleId: adminRole._id, permissionId: p._id });
        console.log(`  ✓ Assigned "${perm.name}" to admin role`);
      }
    }

    console.log("\n✓ Seed completed successfully!");
    console.log("\nYou can create the same menus/permissions on the admin portal; data will update after changes.");
  } catch (e) {
    console.error("\n✗ Error during seeding:", e);
    process.exit(1);
  } finally {
    await mongoose.disconnect();
    console.log("\n✓ MongoDB disconnected");
  }
}

seed();
