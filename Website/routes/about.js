const express = require('express');
const router = express.Router();
const multer = require('multer');
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

// Render the upload page
router.get("/", (req, res) => {
  res.render("about",{currentUser: req.user});;
});
module.exports=router;