const Business = require("../models/Business");

// get all businesses (only admin can access)
const getAllBusinesses = async (req, res) => {
  try {
    res.status(200).json({ message: "Get all businesses" });
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
};
// get business by id (only admin and the business owner can access)
const getBusinessById = async (req, res) => {
  try {
    res.status(200).json({ message: "Get business by ID" });
  } catch (error) {}
};
// create business (authenticated users)
const createBusiness = async (req, res) => {
  try {
    res.status(201).json({ message: "Business created" });
  } catch (error) {}
};
// update business (only business owner can access)
const updateBusiness = async (req, res) => {
  try {
    res.status(200).json({ message: "Business updated" });
  } catch (error) {}
};
// delete business (only admin and the business owner can access)
const deleteBusiness = async (req, res) => {
  try {
    res.status(200).json({ message: "Business deleted" });
  } catch (error) {}
};

module.exports = {
  getAllBusinesses,
  getBusinessById,
  createBusiness,
  updateBusiness,
  deleteBusiness,
};
