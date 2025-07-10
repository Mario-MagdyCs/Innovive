const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const GeneratedProductSchema = new Schema({
  name: {
    type: String,
    required: true,
  },
  category: {
    type: String,
    required: true,
  },
  materials: {
    type: [String],
    required: true,
  },
  measurements: {
    type: Map, // Map<String, String>
    of: String,
    required: true,
  },
  additionalMaterials: {
    type: [String],
    required: true,
  },
  image: {
    type: String,
    required: true,
  },
  user: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  }
},{ timestamps: true });

module.exports = mongoose.model('GeneratedProduct', GeneratedProductSchema);
