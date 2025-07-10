const mongoose=require('mongoose');
const { Schema } = mongoose;

const UserPreferredMaterialsSchema=new Schema({
    userId:{
        type: Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    materials: {
        type: [String],
        default: []
      }
})

module.exports=mongoose.model('UserPreferredMaterials',UserPreferredMaterialsSchema);