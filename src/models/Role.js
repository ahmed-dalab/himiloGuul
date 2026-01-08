const mongoose = require("mongoose");

const roleSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      unique: true,
      trim: true,
    },
  },
  { timestamps: true }
);

// Add index for name
roleSchema.index({ name: 1 });

const Role = mongoose.model("Role", roleSchema);

module.exports = Role;

