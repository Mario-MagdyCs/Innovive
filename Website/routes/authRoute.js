const express = require('express')
const router = express.Router()
const authentication=require('../controllers/AuthController')
const passport=require('passport')

router.get("/register",(req,res)=>{
    res.render("register")
})

router.route('/login')
.get(authentication.renderLogin)
.post(authentication.login)

router.get('/logout',authentication.logout)


module.exports=router;
