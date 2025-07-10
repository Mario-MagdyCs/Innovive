const express = require('express')
const router = express.Router()
const passport = require('passport');
const catchAsync = require('../utils/catchAsync');
const enthUsers=require('../controllers/EnthusiastController')

router.route("/step2")
.get(enthUsers.renderStep2)
.post(catchAsync(enthUsers.register));

router.route("/step3")
.get(enthUsers.renderStep3)
.post(catchAsync(enthUsers.saveUserPreferredMaterials));

router.route("/step4")
.get(enthUsers.renderStep4)
.post(catchAsync(enthUsers.saveUserPreferredCategories));

router.get("/done",enthUsers.renderDone)

module.exports=router;
