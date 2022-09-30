const mongoose = require('mongoose');
const Schema = mongoose.Schema;
const User = new Schema({
  userID: {
    type: String,
    unique: true,
    index: true,
  },
  name: {
    type: String,
    default: null,
  },
  username: {
    type: String,
    default: null,
    require: false,
  },
  email: {
    type: String,
    default: null,
    require: true,
  },
  password: {
    type: String,
    default: null,
    require: true,
  },})

module.exports = mongoose.model('User', User);