const mongoose=require('mongoose');
const { Schema } = mongoose;

const IndustryPreferredCategoriesSchema=new Schema({
    userId:{
        type: Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    categories: {
        type: [String],
        default: []
      }
})

module.exports=mongoose.model('IndustryPreferredCategories',IndustryPreferredCategoriesSchema);