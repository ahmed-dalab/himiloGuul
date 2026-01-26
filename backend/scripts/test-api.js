/**
 * API integration test script.
 * Run: node scripts/test-api.js  (or: npm run test:api)
 * Requires: server running (npm run dev) and MONGO_URI, JWT_SECRET in .env
 * Loads .env so PORT is used. Override: BASE_URL=http://localhost:3000 node scripts/test-api.js
 */

require("dotenv").config({ path: require("path").join(__dirname, "..", ".env") });
const BASE = process.env.BASE_URL || `http://localhost:${process.env.PORT || 5000}`;
const unique = `test-${Date.now()}@example.com`;

async function req(method, path, body = null, token = null) {
  const opts = { method };
  opts.headers = { "Content-Type": "application/json" };
  if (token) opts.headers["Authorization"] = `Bearer ${token}`;
  if (body && (method === "POST" || method === "PUT")) opts.body = JSON.stringify(body);
  const res = await fetch(`${BASE}${path}`, opts);
  const text = await res.text();
  let data;
  try {
    data = text ? JSON.parse(text) : null;
  } catch {
    data = text;
  }
  return { status: res.status, data };
}

async function run() {
  let passed = 0;
  let failed = 0;

  function ok(name, cond, detail = "") {
    if (cond) {
      passed++;
      console.log(`  \u2713 ${name}`);
    } else {
      failed++;
      console.log(`  \u2717 ${name}${detail ? `: ${detail}` : ""}`);
    }
  }

  console.log("\n--- HimiloGuul API tests ---\n");

  // 1. Health
  try {
    const h = await req("GET", "/health");
    ok("GET /health", h.status === 200 && h.data === "Server is healthy");
  } catch (e) {
    ok("GET /health", false, e.message);
  }

  // 2. Auth register (needs role: ensure 'user' or 'buyer' exists in DB; if not, may 400)
  let token = null;
  let userId = null;
  try {
    const reg = await req("POST", "/api/auth/register", {
      name: "API Test User",
      email: unique,
      password: "password123",
      role: "user",
    });
    if (reg.status === 201 && reg.data?.token) {
      token = reg.data.token;
      userId = reg.data.user?._id;
      ok("POST /api/auth/register", true);
    } else if (reg.status === 400 && /role/i.test(reg.data?.message || "")) {
      // Fallback: try "buyer" or "seller" if "user" role missing
      const r2 = await req("POST", "/api/auth/register", {
        name: "API Test User",
        email: unique,
        password: "password123",
        role: "buyer",
      });
      if (r2.status === 201 && r2.data?.token) {
        token = r2.data.token;
        userId = r2.data.user?._id;
        ok("POST /api/auth/register (buyer)", true);
      } else {
        ok("POST /api/auth/register", false, ` ${r2.status} ${JSON.stringify(r2.data)}`);
      }
    } else {
      ok("POST /api/auth/register", false, ` ${reg.status} ${JSON.stringify(reg.data)}`);
    }
  } catch (e) {
    ok("POST /api/auth/register", false, e.message);
  }

  // 3. Auth login
  try {
    const login = await req("POST", "/api/auth/login", { email: unique, password: "password123" });
    if (login.status === 200 && login.data?.token) {
      token = login.data.token;
      ok("POST /api/auth/login", true);
    } else {
      ok("POST /api/auth/login", false, ` ${login.status} ${JSON.stringify(login.data)}`);
    }
  } catch (e) {
    ok("POST /api/auth/login", false, e.message);
  }

  // 4. Users profile (needs token)
  try {
    const pro = await req("GET", "/api/users/profile", null, token);
    ok("GET /api/users/profile", pro.status === 200 && pro.data?.user != null);
  } catch (e) {
    ok("GET /api/users/profile", false, e.message);
  }

  // 5. User by ID (public)
  if (userId) {
    try {
      const ub = await req("GET", `/api/users/${userId}`);
      ok("GET /api/users/:id", ub.status === 200 && ub.data?.user != null);
    } catch (e) {
      ok("GET /api/users/:id", false, e.message);
    }
  }

  // 6. Browse businesses (public)
  try {
    const browse = await req("GET", "/api/business");
    ok("GET /api/business (browse)", browse.status === 200 && Array.isArray(browse.data?.data));
  } catch (e) {
    ok("GET /api/business (browse)", false, e.message);
  }

  // 7. Menus (public)
  try {
    const menus = await req("GET", "/api/menus");
    ok("GET /api/menus", menus.status === 200 && Array.isArray(menus.data?.menus));
  } catch (e) {
    ok("GET /api/menus", false, e.message);
  }

  // 8. Protected route without token
  try {
    const noTok = await req("GET", "/api/users/profile");
    ok("GET /api/users/profile (no token) fails", noTok.status === 401);
  } catch (e) {
    ok("GET /api/users/profile (no token) fails", false, e.message);
  }

  console.log(`\n--- Done: ${passed} passed, ${failed} failed ---\n`);
  process.exit(failed > 0 ? 1 : 0);
}

run().catch((e) => {
  console.error(e);
  process.exit(1);
});
