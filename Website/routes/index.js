const express = require('express')
const router = express.Router()

router.get("/",(req,res)=>{
    res.render("index",{currentUser: req.user});
});

module.exports=router;