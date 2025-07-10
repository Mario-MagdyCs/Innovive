const mongoose = require('mongoose');
const User = require('../User');

const EnthusiastUserSchema = new mongoose.Schema({
  fullName: { type: String, required: true },
  age: { type: Number, required: true },
  gender: { type: String, enum: ['Male', 'Female', 'Other'], required: true }
});

module.exports = User.discriminator('Enthusiast', EnthusiastUserSchema);
