/**
 * RBAC Seed: Role-Based Access Control with permission-driven menu visibility.
 * Run: node scripts/seed-rbac.js
 * Requires: MONGO_URI in .env
 *
 * Design:
 * - Each Permission has exactly one menu (menuId). No MenuPermission table.
 * - RolePermission links Role to Permission (which permissions a role has).
 * - A user sees a menu if their role has at least one permission whose menuId is that menu.
 *
 * Creates:
 * - Roles: admin, seller, buyer (if not exist)
 * - Admin user: ali@gmail.com / admin123 (if not exist)
 * - Seller test user: seller@example.com / seller123 (if not exist)
 * - Buyer test user: buyer@example.com / buyer123 (if not exist)
 * - Menus: seller + admin portal menus (by path)
 * - Permissions: each with one menuId (view_seller_*, view_admin_*, manage_*)
 * - RolePermission: seller gets view_seller_*; admin gets all permissions
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
const SELLER_EMAIL = "seller@example.com";
const SELLER_PASSWORD = "seller123";
const BUYER_EMAIL = "buyer@example.com";
const BUYER_PASSWORD = "buyer123";
const ADMIN_ROLE_NAME = "admin";
const SELLER_ROLE_NAME = "seller";
const BUYER_ROLE_NAME = "buyer";

// All menus: path must be unique
const SEED_MENUS = [
  { name: "Home", path: "/seller/dashboard" },
  { name: "My Business", path: "/seller/my-businesses" },
  { name: "Contacts", path: "/seller/contacts" },
  { name: "Profile", path: "/seller/profile" },
  { name: "Home", path: "/admin" },
  { name: "Business", path: "/admin/business" },
  { name: "Users", path: "/admin/users" },
  { name: "Roles", path: "/admin/roles" },
  { name: "Permissions", path: "/admin/permissions" },
  { name: "Role Permissions", path: "/admin/role-permissions" },
  { name: "Menus", path: "/admin/menus" },
  { name: "Settings", path: "/admin/settings" },
  { name: "Profile", path: "/admin/profile" },
  // Hidden/system menu used to attach API-only permissions (not shown in /api/menus/me)
  { name: "System", path: "/__system" },
];

// Permission name -> single menu path (one permission = one menu)
const PERMISSION_TO_MENU_PATH = {
  // Seller portal
  view_seller_dashboard: "/seller/dashboard",
  view_seller_my_businesses: "/seller/my-businesses",
  view_seller_contacts: "/seller/contacts",
  view_seller_profile: "/seller/profile",

  // API-only permissions (attached to hidden system menu)
  view_profile: "/__system",
  update_profile: "/__system",

  create_business: "/__system",
  update_business: "/__system",
  delete_business: "/__system",
  mark_business_sold: "/__system",
  manage_business_approval: "/__system",

  create_contact: "/__system",
  view_my_contacts: "/__system",
  view_contact: "/__system",
  update_contact: "/__system",
  delete_contact: "/__system",
  manage_contacts: "/__system",

  view_admin_activities: "/__system",

  // Admin portal (view + manage; multiple permissions can point to same menu)
  view_admin_dashboard: "/admin",
  view_admin_business: "/admin/business",
  view_admin_users: "/admin/users",
  manage_users: "/admin/users",
  view_admin_roles: "/admin/roles",
  manage_roles: "/admin/roles",
  view_admin_permissions: "/admin/permissions",
  manage_permissions: "/admin/permissions",
  view_admin_role_permissions: "/admin/role-permissions",
  manage_role_permissions: "/admin/role-permissions",
  view_admin_menus: "/admin/menus",
  manage_menus: "/admin/menus",
  view_admin_settings: "/admin/settings",
  manage_settings: "/admin/settings",
  view_admin_profile: "/admin/profile",

  update_user: "/__system",
  delete_user: "/__system",
  view_menus_me: "/__system",
};

const SELLER_PERMISSION_NAMES = [
  "view_seller_dashboard",
  "view_seller_my_businesses",
  "view_seller_contacts",
  "view_seller_profile",
  "view_profile",
  "update_profile",
  "create_business",
  "update_business",
  "delete_business",
  "mark_business_sold",
  "create_contact",
  "view_my_contacts",
  "view_contact",
  "update_contact",
  "delete_contact",
  "update_user",
  "delete_user",
  "view_menus_me",
];

const BUYER_PERMISSION_NAMES = [
  "view_profile",
  "update_profile",
  "create_contact",
  "view_my_contacts",
  "view_contact",
  "update_contact",
  "delete_contact",
  "update_user",
  "delete_user",
  "view_menus_me",
];

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
    let buyerRole = await Role.findOne({ name: BUYER_ROLE_NAME });
    if (!buyerRole) {
      buyerRole = await Role.create({ name: BUYER_ROLE_NAME });
      console.log(`  ✓ Created role "${BUYER_ROLE_NAME}"`);
    } else {
      console.log(`  ✓ Role "${BUYER_ROLE_NAME}" already exists`);
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

    // 2b. Seller test user
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

    // 2c. Buyer test user
    console.log("\n=== Buyer Test User ===");
    const existingBuyer = await User.findOne({ email: BUYER_EMAIL });
    if (existingBuyer) {
      if (existingBuyer.roleId?.toString() !== buyerRole._id.toString()) {
        existingBuyer.roleId = buyerRole._id;
        await existingBuyer.save();
        console.log(`  ✓ Updated user role to buyer`);
      } else {
        console.log(`  ✓ User ${BUYER_EMAIL} already exists`);
      }
    } else {
      const hashedBuyerPassword = await bcrypt.hash(BUYER_PASSWORD, 10);
      await User.create({
        name: "Test Buyer",
        email: BUYER_EMAIL,
        password: hashedBuyerPassword,
        roleId: buyerRole._id,
      });
      console.log(`  ✓ Created user ${BUYER_EMAIL} (password: ${BUYER_PASSWORD})`);
    }

    // 3. Menus (by path)
    console.log("\n=== Menus ===");
    const menuByPath = {};
    for (const menu of SEED_MENUS) {
      let m = await Menu.findOne({ path: menu.path });
      if (!m) {
        const isActive = menu.path === "/__system" ? false : true;
        m = await Menu.create({ name: menu.name, path: menu.path, parentId: null, isActive });
        console.log(`  ✓ Created menu "${menu.name}" (${menu.path})`);
      } else {
        // Ensure /__system stays hidden
        if (menu.path === "/__system" && m.isActive !== false) {
          m.isActive = false;
          await m.save();
          console.log(`  ✓ Updated menu "${menu.name}" (${menu.path}) isActive=false`);
        }
        console.log(`  ✓ Menu "${menu.name}" (${menu.path}) already exists`);
      }
      menuByPath[menu.path] = m;
    }

    // 4. Permissions (each with one menuId)
    console.log("\n=== Permissions (one per menu relationship) ===");
    const permissionByName = {};
    for (const [name, path] of Object.entries(PERMISSION_TO_MENU_PATH)) {
      const menu = menuByPath[path];
      if (!menu) {
        console.warn(`  ⚠ Skipping permission "${name}": menu path ${path} not found`);
        continue;
      }
      let p = await Permission.findOne({ name });
      if (!p) {
        p = await Permission.create({ name, menuId: menu._id });
        console.log(`  ✓ Created permission "${name}" → ${path}`);
      } else {
        if (p.menuId?.toString() !== menu._id.toString()) {
          p.menuId = menu._id;
          await p.save();
          console.log(`  ✓ Updated permission "${name}" menuId → ${path}`);
        } else {
          console.log(`  ✓ Permission "${name}" already exists`);
        }
      }
      permissionByName[name] = p;
    }

    // 5. RolePermission: seller gets view_seller_*; admin gets all
    console.log("\n=== Role Permissions ===");
    const allPermissionNames = Object.keys(PERMISSION_TO_MENU_PATH);
    for (const name of allPermissionNames) {
      const p = permissionByName[name];
      if (!p) continue;

      const assignToSeller = SELLER_PERMISSION_NAMES.includes(name);
      const assignToBuyer = BUYER_PERMISSION_NAMES.includes(name);
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
      if (assignToBuyer) {
        const existsBuyer = await RolePermission.findOne({
          roleId: buyerRole._id,
          permissionId: p._id,
        });
        if (!existsBuyer) {
          await RolePermission.create({ roleId: buyerRole._id, permissionId: p._id });
          console.log(`  ✓ Assigned "${name}" to buyer`);
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
    console.log("\nDesign: Permission has one menuId; RolePermission links Role to Permission.");
    console.log("Seller sees: Home, My Business, Contacts, Profile (via view_seller_* permissions).");
    console.log("Admin sees: all menus (admin has all permissions).");
  } catch (e) {
    console.error("\n✗ Error during seeding:", e);
    process.exit(1);
  } finally {
    await mongoose.disconnect();
    console.log("\n✓ MongoDB disconnected");
  }
}

seed();
