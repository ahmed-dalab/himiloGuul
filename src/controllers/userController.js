const User = require("../models/User");
//  register user
const registerUser = async (req, res) => {
  try {
    res.status(201).json({ message: "User registered" });
  } catch (error) {}
};
//  login user
const login = async (req, res) => {
  try {
    res.status(200).json({ message: "User logged in" });
  } catch (error) {}
};
// get user profile
const getUserProfile = async (req, res) => {
  try {
    res.status(200).json({ message: "Get user profile" });
  } catch (error) {}
};
//  get all users
const getAllUsers = async (req, res) => {
  try {
    res.status(200).json({ message: "Get all users" });
  } catch (error) {}
};
// get user by id
const getUserById = async (req, res) => {
  try {
    res.status(200).json({ message: "Get user by ID" });
  } catch (error) {}
};
//  update user
const updateUser = async (req, res) => {
  try {
    res.status(200).json({ message: "Update user" });
  } catch (error) {}
};
//  delete user
const deleteUser = async (req, res) => {
  try {
    res.status(200).json({ message: "Delete user" });
  } catch (error) {}
};

module.exports = {
  registerUser,
  login,
  getUserProfile,
  getAllUsers,
  getUserById,
  updateUser,
  deleteUser,
};
