const IndustrialUser=require('../models/IndRegistration/IndustrialUser');
const IndustryCategories=require('../models/IndRegistration/IndustryPreferredCategories');
const IndustryManufacturingProcess=require('../models/IndRegistration/IndustryManufacturingProcess');
const IndustryAutomationLevel=require('../models/IndRegistration/IndustryAutomationLevel');
const IndustryMaterials=require('../models/IndRegistration/IndustryMaterials')

module.exports.renderStep2=(req,res)=>{
    res.render("Industrial Registration/step2")
}
module.exports.renderStep3=(req,res)=>{
    res.render("Industrial Registration/step3")
}

module.exports.renderStep4=(req,res)=>{
    res.render("Industrial Registration/step4")
}

module.exports.renderStep5=(req,res)=>{
    res.render("Industrial Registration/step5")
}

module.exports.renderStep6=(req,res)=>{
    res.render("Industrial Registration/step6")
}

module.exports.renderDone=(req,res)=>{
    res.render("Industrial Registration/ind-done")
}

module.exports.register=async(req,res,next)=>{
    try {
        const { email, password, companyName,country } = req.body;
        const newUser = new IndustrialUser({ email, companyName, country});
        const registeredUser = await IndustrialUser.register(newUser, password);
        req.login(registeredUser, err => {
            if (err) return next(err);
            res.redirect('/register-industrial/step3');
        })
        
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: error.message });
    }
}

module.exports.saveIndustryPreferredCategories = async (req, res, next) => {
    try {
        const categories = req.body.industry_categories;
        const userId = req.user._id;

        const IndustryPreferredCategories = new IndustryCategories({
            userId,
            categories
        });

        await IndustryPreferredCategories.save();

        res.status(200).json({ message: "Industry preferred categories saved." });
    } catch (err) {
        console.error("Error saving industry preferred categories:", err);
        res.status(500).json({ error: "Something went wrong." });
    }
};

module.exports.saveManufacturingProcesses = async (req, res, next) => {
    try {
        const processes = req.body.processes;
        const userId = req.user._id;

        const manufacturingProcesses = new IndustryManufacturingProcess({
            userId,
            processes
        });

        await manufacturingProcesses.save();

        res.status(200).json({ message: "Industry manufacturing processes saved." });
    } catch (err) {
        console.error("Error saving industry manufacturing processes:", err);
        res.status(500).json({ error: "Something went wrong." });
    }
};

module.exports.saveAutomationLevel=async (req,res,next)=>{
    try {
        const automation_level = req.body.automation;
        const userId = req.user._id;

        const automationLevel = new IndustryAutomationLevel({
            userId,
            level:automation_level
        });

        await automationLevel.save();

        res.status(200).json({ message: "Industry automation level saved." });
    } catch (err) {
        console.error("Error saving industry automation level:", err);
        res.status(500).json({ error: "Something went wrong." });
    }
}


module.exports.saveIndustryMaterials = async (req, res, next) => {
    try {
        const materials = req.body.materials;
        const userId = req.user._id;

        const industryMaterialsEntry = new IndustryMaterials({
            userId,
            materials
        });

        await industryMaterialsEntry.save();

        res.status(200).json({ message: "Industry materials saved." });
    } catch (err) {
        console.error("Error saving industry materials:", err);
        res.status(500).json({ error: "Something went wrong." });
    }
};
