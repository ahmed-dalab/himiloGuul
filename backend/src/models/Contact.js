const mongoose = require("mongoose");

const contactSchema = new mongoose.Schema(
  {
    buyerRef: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    sellerRef: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    businessRef: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Business",
      required: true,
    },
    name: {
      type: String,
      required: true,
    },
    email: {
      type: String,
      required: true,
    },
    phone: {
      type: String,
    },
    message: {
      type: String,
      required: true,
    },
    reply: {
      type: String,
      default: null,
    },
    repliedAt: {
      type: Date,
      default: null,
    },
    status: {
      type: String,
      enum: ["pending", "responded", "closed"],
      default: "pending",
    },
  },
  { timestamps: true }
);

// Ensure unique contact per buyer-seller-business combination
contactSchema.index({ buyerRef: 1, sellerRef: 1, businessRef: 1 }, { unique: true });

// Add indexes for better query performance
contactSchema.index({ buyerRef: 1 });
contactSchema.index({ sellerRef: 1 });
contactSchema.index({ businessRef: 1 });
contactSchema.index({ status: 1 });

const Contact = mongoose.model("Contact", contactSchema);

module.exports = Contact;
