const passport=require('passport')

module.exports.renderLogin=(req,res)=>{
    console.log(req.session.returnTo)
    res.render('login')
} 

module.exports.login = (req, res, next) => {
    var returnTo = req.session.returnTo;
    if (returnTo && returnTo.includes('upload')) {
        returnTo = returnTo.split('/').slice(0, 2).join('/');
    }

    passport.authenticate('local', (err, user, info) => {
        if (err) {
            console.error("Authentication Error:", err);
            return next(err);
        }
        if (!user) {
            req.flash('error', 'Invalid email or password.');
            return res.redirect('/auth/login');
        }

        // Login user
        req.logIn(user, (err) => {
            if (err) {
                console.error("Login Error:", err);
                return next(err);
            }

            req.session.returnTo = returnTo;
            req.session.save((err) => {
                if (err) {
                    console.error("Session Save Error after Login:", err);
                }
                if(returnTo && returnTo.includes("upload") && req.user.userType==="Industrial"){
                    req.session.returnTo="/select-materials"
                }
                res.redirect(req.session.returnTo || '/');
            });
        });
    })(req, res, next);
};


module.exports.logout = (req, res, next) => {
    req.logout(function(err) {
        if (err) { return next(err); }
        req.flash('success', 'You have been logged out.');
        res.redirect('/');
    });
};
