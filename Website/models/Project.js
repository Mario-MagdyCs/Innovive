const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const GeneratedProjectSchema = new Schema({
  name: {
    type: String,
    required: true
  },
  level: {
    type: String,
    required: true
  },
  materials: [
    {
      title: {
        type: String,
        required: true
      },
      description: {
        type: String,
        required: true
      }
    }
  ],
  instructions: [
    {
      title: {
        type: String,
        required: true
      },
      description: {
        type: String,
        required: true
      }
    }
  ],
  image: {
    type: String,
    required: true
  },
  mainmaterials: {
    type: [String],
    required: true
  },
  user: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  shared: {
    type: Boolean,
    required: true
  },
  likes: [{
    type: Schema.Types.ObjectId,
    ref: 'User'
  }],
  dislikes: [{
    type: Schema.Types.ObjectId,
    ref: 'User'
  }],
  uploads: [
    {
      imagePath: {
        type: String,
      },
      accepted_by_admin: {
        type: Boolean,
        default: false
      }
    }
  ]
}, { timestamps: true });

module.exports = mongoose.model('GeneratedProject', GeneratedProjectSchema);
