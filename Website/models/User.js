const mongoose = require('mongoose');
const Schema = mongoose.Schema;
const passportLocalMongoose = require('passport-local-mongoose');

const BaseUserSchema = new Schema({
  email: { type: String, required: true, unique: true },
  fullName: { type: String },
  age: { type: Number },
  gender: { type: String },
  preferredMaterials: {
    type: Schema.Types.ObjectId,
    ref: 'UserPreferredMaterials'
  },
  points: { type: Number, default: 0 },
  badges: [{
    badgeId: { type: String }, // e.g. "plastic_master"
    earnedAt: { type: Date, default: Date.now }
  }],
  favorites: [{ type: Schema.Types.ObjectId, ref: 'GeneratedProject' }],
  likes: [{ type: Schema.Types.ObjectId, ref: 'GeneratedProject' }],
  dislikes: [{ type: Schema.Types.ObjectId, ref: 'GeneratedProject' }]
}, { discriminatorKey: 'userType', timestamps: true });

BaseUserSchema.plugin(passportLocalMongoose, {
  usernameField: 'email'
});

module.exports = mongoose.model('User', BaseUserSchema);
