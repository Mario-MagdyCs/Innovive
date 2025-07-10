const mongoose=require('mongoose');
const { Schema } = mongoose;

const IndustryManufacturingProcessSchema=new Schema({
    userId:{
        type: Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    processes: {
        type: [String],
        default: []
      }
})

module.exports=mongoose.model('IndustryManufacturingProcess',IndustryManufacturingProcessSchema);