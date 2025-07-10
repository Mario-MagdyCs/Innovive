const mongoose=require('mongoose');
const { Schema } = mongoose;

const IndustryAutomationLevelSchema=new Schema({
    userId:{
        type: Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    level: {
        type: String,
        enum:["Fully Automated","Partially Manual", "Handmade"]
    }
})

module.exports=mongoose.model('IndustryAutomationLevel',IndustryAutomationLevelSchema);