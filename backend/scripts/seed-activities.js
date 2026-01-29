/**
 * Seed sample recent activities. Run: node scripts/seed-activities.js
 * Requires: MONGO_URI in .env
 * Creates sample activities if the collection is empty.
 */

require("dotenv").config();
const mongoose = require("mongoose");
const connectDB = require("../src/config/db");
const Activity = require("../src/models/Activity");

const SAMPLE_ACTIVITIES = [
  { type: "user_registered", description: "New user registered" },
  { type: "business_listed", description: "New business listed" },
  { type: "deal_closed", description: "Deal closed" },
  { type: "user_updated", description: "User profile updated" },
  { type: "business_updated", description: "Business profile updated" },
];

function hoursAgo(h) {
  const d = new Date();
  d.setHours(d.getHours() - h);
  return d;
}

async function seed() {
  await connectDB();
  const count = await Activity.countDocuments();
  if (count > 0) {
    console.log("Activities already exist, skipping seed.");
    process.exit(0);
    return;
  }
  const docs = SAMPLE_ACTIVITIES.map((a, i) => ({
    ...a,
    createdAt: hoursAgo([2, 5, 24, 48, 72][i] || 0),
  }));
  await Activity.insertMany(docs);
  console.log(`Inserted ${docs.length} sample activities.`);
  process.exit(0);
}

seed().catch((err) => {
  console.error(err);
  process.exit(1);
});
