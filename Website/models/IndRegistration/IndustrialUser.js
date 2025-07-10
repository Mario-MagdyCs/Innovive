const mongoose = require('mongoose');
const User = require('../User');

const IndustrialUserSchema = new mongoose.Schema({
  companyName: { type: String, required: true },
  country: { type: String, required: true }
});

module.exports = User.discriminator('Industrial', IndustrialUserSchema);
