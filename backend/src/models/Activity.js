const mongoose = require("mongoose");

const activitySchema = new mongoose.Schema(
  {
    type: {
      type: String,
      required: true,
      enum: [
        "user_registered",
        "business_listed",
        "deal_closed",
        "user_updated",
        "business_updated",
        "business_approved",
        "business_rejected",
        "contact_created",
      ],
    },
    description: {
      type: String,
      required: true,
    },
    relatedId: {
      type: mongoose.Schema.Types.ObjectId,
      refPath: "relatedModel",
    },
    relatedModel: {
      type: String,
      enum: ["User", "Business", "Contact"],
    },
    metadata: {
      type: mongoose.Schema.Types.Mixed,
    },
  },
  { timestamps: true }
);

activitySchema.index({ createdAt: -1 });

const Activity = mongoose.model("Activity", activitySchema);

module.exports = Activity;
