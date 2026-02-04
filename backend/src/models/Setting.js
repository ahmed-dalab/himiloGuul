const mongoose = require("mongoose");

/**
 * App settings (singleton: one document).
 * Stores appName, contactEmail, timezone. Other settings (2FA, password policy) are future.
 */
const settingSchema = new mongoose.Schema(
  {
    appName: {
      type: String,
      trim: true,
      default: "HimiloGuul",
    },
    contactEmail: {
      type: String,
      trim: true,
      default: "",
    },
    timezone: {
      type: String,
      trim: true,
      default: "UTC",
    },
  },
  { timestamps: true }
);

const Setting = mongoose.model("Setting", settingSchema);

module.exports = Setting;
