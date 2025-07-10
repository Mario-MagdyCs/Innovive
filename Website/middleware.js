
// module.exports.isLoggedIn = (req, res, next) => {
//     if (!req.isAuthenticated()) {
//         req.session.returnTo = req.originalUrl
//         req.flash('error', 'You must be signed in first!');
//         return res.redirect('/login');
//     }
//     next();
// }

module.exports.isLoggedIn = (req, res, next) => {
  if (!req.isAuthenticated()) {
    if (req.method === 'GET' || req.method === 'POST') {
      req.session.returnTo = req.originalUrl;
      console.log("Session returnTo set:", req.session.returnTo);
    }
    req.session.save((err) => {
      if (err) console.error("Session save error:", err);
      if (req.headers.accept && req.headers.accept.includes('application/json')) {
        console.log("json")
        return res.status(401).json({ redirectUrl: '/auth/login' });
      } else {
        return res.redirect('/auth/login');
      }
    });
  }else{
    next();
  }
};



