const Setting = require("../models/Setting");

const SETTINGS_ID = "app"; // single document id for app settings (we use findOne by id or first doc)

/**
 * GET /api/settings - Get app settings (create default if none).
 */
const getSettings = async (req, res) => {
  try {
    let settings = await Setting.findOne();
    if (!settings) {
      settings = await Setting.create({
        appName: "HimiloGuul",
        contactEmail: "",
        timezone: "UTC",
      });
    }
    res.status(200).json({
      success: true,
      data: {
        _id: settings._id,
        appName: settings.appName ?? "HimiloGuul",
        contactEmail: settings.contactEmail ?? "",
        timezone: settings.timezone ?? "UTC",
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to fetch settings",
      error: error.message,
    });
  }
};

/**
 * PUT /api/settings - Create or update app settings (upsert).
 */
const updateSettings = async (req, res) => {
  try {
    const { appName, contactEmail, timezone } = req.body;

    let settings = await Setting.findOne();
    if (!settings) {
      settings = new Setting({
        appName: appName ?? "HimiloGuul",
        contactEmail: contactEmail ?? "",
        timezone: timezone ?? "UTC",
      });
    } else {
      if (appName !== undefined) settings.appName = appName;
      if (contactEmail !== undefined) settings.contactEmail = contactEmail;
      if (timezone !== undefined) settings.timezone = timezone;
    }
    await settings.save();

    res.status(200).json({
      success: true,
      message: "Settings updated successfully",
      data: {
        _id: settings._id,
        appName: settings.appName ?? "HimiloGuul",
        contactEmail: settings.contactEmail ?? "",
        timezone: settings.timezone ?? "UTC",
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to update settings",
      error: error.message,
    });
  }
};

module.exports = {
  getSettings,
  updateSettings,
};
