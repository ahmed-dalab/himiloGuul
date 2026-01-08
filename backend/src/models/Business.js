const mongoose = require("mongoose");

const businessSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
    },
    address: {
      type: String,
      required: true,
    },
    phone: {
      type: String,
      required: true,
    },
    email: {
      type: String,
      required: true,
      unique: true,
    },
    website: {
      type: String,
    },
    owner: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    description: {
      type: String,
    },
    category: {
      type: String,
      enum: [
        "restaurant",
        "retail",
        "service",
        "technology",
        "healthcare",
        "education",
        "real-estate",
        "hospitality",
        "other",
      ],
    },
    askingPrice: {
      type: Number,
      min: 0,
    },
    location: {
      type: String,
    },
    images: [
      {
        url: {
          type: String,
          required: true,
        },
        publicId: {
          type: String,
          required: true,
        },
      },
    ],
    status: {
      type: String,
      enum: ["pending", "approved", "rejected"],
      default: "pending",
    },
    isSold: {
      type: Boolean,
      default: false,
    },
  },
  { timestamps: true }
);

// Add indexes for better query performance
businessSchema.index({ category: 1 });
businessSchema.index({ location: 1 });
businessSchema.index({ askingPrice: 1 });
businessSchema.index({ status: 1 });
businessSchema.index({ owner: 1 });
businessSchema.index({ name: "text", description: "text" }); // Text search index

const Business = mongoose.model("Business", businessSchema);

module.exports = Business;
