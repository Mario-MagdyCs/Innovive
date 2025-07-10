const EnthusiastUser=require('../models/EnthRegistration/EnthusiastUser');
const UserPreferredMaterials=require('../models/EnthRegistration/UserPreferredMaterials')
const UserPreferredCategories=require('../models/EnthRegistration/UserPreferredCategories')

module.exports.renderStep2=(req,res)=>{
    res.render("Enthusiast Registration/step2")
}
module.exports.renderStep3=(req,res)=>{
    res.render("Enthusiast Registration/step3")
}

module.exports.renderStep4=(req,res)=>{
    res.render("Enthusiast Registration/step4")
}

module.exports.renderDone=(req,res)=>{
    res.render("Enthusiast Registration/enth-done")
}

module.exports.register=async(req,res,next)=>{
    try {
        const { email, password, fullName, age, gender } = req.body;
        const newUser = new EnthusiastUser({ email, fullName, age, gender });
        const registeredUser = await EnthusiastUser.register(newUser, password);
        req.login(registeredUser, err => {
            if (err) return next(err);
            res.redirect('/register-enthusiast/step3');
        })
        
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: error.message });
    }
}

module.exports.saveUserPreferredMaterials = async (req, res, next) => {
    try {
        const materials = req.body.materials;
        const userId = req.user._id;

        const userPreferredMaterials = new UserPreferredMaterials({
            userId,
            materials
        });

        await userPreferredMaterials.save();

        res.status(200).json({ message: "User preferred materials saved." });
    } catch (err) {
        console.error("Error saving user preferred materials:", err);
        res.status(500).json({ error: "Something went wrong." });
    }
};


module.exports.saveUserPreferredCategories = async (req, res, next) => {
    try {
        const categories = req.body.categories;
        const userId = req.user._id;

        const userPreferredCategories = new UserPreferredCategories({
            userId,
            categories
        });

        await userPreferredCategories.save();

        res.status(200).json({ message: "User preferred categories saved." });
    } catch (err) {
        console.error("Error saving user preferred categories:", err);
        res.status(500).json({ error: "Something went wrong." });
    }
};
