const express = require('express')
const router = express.Router()
const passport = require('passport');
const catchAsync = require('../utils/catchAsync');
const indUsers=require('../controllers/IndustrialController')

router.route("/step2")
.get(indUsers.renderStep2)
.post(catchAsync(indUsers.register));

router.route("/step3")
.get(indUsers.renderStep3)
.post(catchAsync(indUsers.saveIndustryPreferredCategories));

router.route("/step4")
.get(indUsers.renderStep4)
.post(catchAsync(indUsers.saveManufacturingProcesses));

router.route("/step5")
.get(indUsers.renderStep5)
.post(catchAsync(indUsers.saveAutomationLevel));

router.route("/step6")
.get(indUsers.renderStep6)
.post(catchAsync(indUsers.saveIndustryMaterials));

router.get("/done",indUsers.renderDone)


module.exports=router;
