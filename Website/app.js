const express = require("express");
const session = require("express-session");
const app = express();
const mongoose = require("mongoose");
const ExpressError = require('./utils/ExpressError');
const logger=require("morgan");
const bodyParser = require("body-parser");
let path = require("path");
const flash = require('connect-flash');
const cors = require("cors");
const dotenv=require("dotenv")
const passport = require('passport');
const LocalStrategy = require('passport-local');
const User = require('./models/User');
const GeneratedProject = require('./models/Project')
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

const sessionConfig = {
  secret: 'innovivesecretsession',
  resave: false,
  saveUninitialized: true,
  cookie: {
      httpOnly: true,
      maxAge: 1000 * 60 * 60 * 24 * 7
  }
}

app.use(session(sessionConfig))

dotenv.config()


// Increase body size limit for JSON and URL-encoded data
app.use(bodyParser.json({ limit: '10mb' })); // Adjust the limit as needed
app.use(bodyParser.urlencoded({ limit: '10mb', extended: true }));


// const sampleProjects = [
//   {
//     name: "Plastic Bottle Herb Garden",
//     image: "Plastic Bottle Herb Garden.jpg",
//     materials: ["Plastic bottle", "Twine", "Soil", "Seeds"],
//     instructions: [
//       "Cut the bottle horizontally.",
//       "Fill the bottom half with soil.",
//       "Plant herb seeds inside.",
//       "Hang the bottle using twine by a window."
//     ],
//     level: "beginner",
//     generatedBy: "AI"
//   },
//   {
//     name: "Plastic Bottle Chandelier",
//     image: "Plastic Bottle Chandelier.jpg",
//     materials: ["Plastic bottle", "LED lights", "Wire", "Glue"],
//     instructions: [
//       "Cut the bottoms of multiple bottles.",
//       "Shape and glue them together in layers.",
//       "Attach LED lights in the center.",
//       "Hang the chandelier using wire from the ceiling."
//     ],
//     level: "advanced",
//     generatedBy: "User"
//   },
//   {
//     name: "Tin Can Pencil Holder",
//     image: "Tin Can Pencil Holder.jpg",
//     materials: ["Tin can", "Fabric", "Glue", "Scissors"],
//     instructions: [
//       "Clean the tin can thoroughly.",
//       "Cut a piece of fabric to wrap around it.",
//       "Glue the fabric onto the can.",
//       "Let it dry and use it as a pencil holder."
//     ],
//     level: "beginner",
//     generatedBy: "AI"
//   },
//   {
//     name: "Tin Can Wind Chime",
//     image: "Tin Can Wind Chime.jpg",
//     materials: ["Tin can", "Paint", "String", "Beads"],
//     instructions: [
//       "Paint and decorate the cans.",
//       "Drill holes in the bottoms.",
//       "Tie strings with beads and hang them from a stick.",
//       "Mount the chime outdoors."
//     ],
//     level: "intermediate",
//     generatedBy: "User"
//   },
//   {
//     name: "Glass Bottle Lamp",
//     image: "Glass Bottle Lamp.jpg",
//     materials: ["Glass bottle", "Fairy lights", "Drill", "Rubber grommet"],
//     instructions: [
//       "Drill a hole near the bottom of the bottle.",
//       "Insert the fairy lights through the hole.",
//       "Place a grommet to protect the wire.",
//       "Plug in and enjoy your lamp."
//     ],
//     level: "intermediate",
//     generatedBy: "AI"
//   },
//   {
//     name: "Painted Glass Bottle Vase",
//     image: "Painted Glass Bottle Vase.jpg",
//     materials: ["Glass bottle", "Acrylic paint", "Brushes", "Ribbon"],
//     instructions: [
//       "Clean and dry the glass bottle.",
//       "Paint it with patterns or a solid color.",
//       "Let it dry and tie a ribbon around the neck.",
//       "Use it to hold flowers."
//     ],
//     level: "beginner",
//     generatedBy: "User"
//   }
// ];

//Connect to MongoDB
console.log(process.env.MONGO_URI);
mongoose.connect(process.env.MONGO_URI , {
  useNewUrlParser: true,
  useUnifiedTopology: true
}).then(() => {
  console.log('MongoDB connected');
}).catch((err) => {
  console.error('MongoDB connection error:', err);
});


app.use(express.urlencoded({ extended: true }));
app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.json());
app.use(bodyParser.json());
app.use(express.static("public"));

app.set("view engine", "ejs");
app.use(logger("dev"));
app.use(cors({ origin: true }));
app.use(express.static(path.join(__dirname, "public"))); 

 

app.use(flash());

app.use(passport.initialize());
app.use(passport.session());
passport.use(new LocalStrategy({ usernameField: 'email' }, User.authenticate()));

passport.use(User.createStrategy());
passport.serializeUser(User.serializeUser());
passport.deserializeUser(User.deserializeUser());

const index=require("./routes/index.js")
const authRoute=require("./routes/authRoute.js")
const isLoggedIn = require('./middleware').isLoggedIn;
const upload=require("./routes/upload.js")
const selectMaterialsRoute=require("./routes/select-materials.js")
const enthusiastRoute=require('./routes/enthusiast.js')
const industrialRoute=require('./routes/industrial.js')
const projectRoute=require('./routes/project.js')
const productRoute=require('./routes/product.js')
const profile=require("./routes/profile_info.js")
const projects=require("./routes/projects.js")
const report=require("./routes/report.js")
const Service=require("./routes/Service.js")
const contact=require("./routes/contact.js")
const about=require("./routes/about.js")
const chatbot=require("./routes/chatbot.js")
const sustainability_report =require("./routes/sustainability_report.js")
const recycled_history =require("./routes/recycled_history.js")
const achievements =require("./routes/achievements.js")
const admin =require("./routes/admin.js")
const adminPendingRoutes = require('./routes/admin-pending.js');

const adminUser = require('./routes/adminUser.js');
const favorites = require('./routes/favourties.js');

app.use("/", index);
app.use("/auth",authRoute);
app.use("/upload",upload);
app.use("/select-materials",selectMaterialsRoute);
app.use("/register-enthusiast",enthusiastRoute)
app.use("/register-industrial",industrialRoute)
app.use("/generated-projects", projectRoute)
app.use("/product", productRoute)
app.use("/profile_info", profile)
app.use("/projects", projects)
app.use("/report", report)
app.use("/Service", Service)
app.use("/contact", contact)
app.use("/about", about)
app.use("/chatbot", chatbot)
app.use("/sustainability_report", sustainability_report)
app.use("/recycled_history", recycled_history)
app.use("/achievements", achievements)
app.use("/admin", admin)
app.use('/admin-pending', adminPendingRoutes);
app.use('/adminUser', adminUser);
app.use('/favourites', favorites);


// 404 handler
app.use((req, res, next) => {
  res.status(404).render('404');
});


// app.all('*', (req, res, next) => {
//     next(new ExpressError('Page Not Found', 404))
// })

// app.use((err, req, res, next) => {
//     const { statusCode = 500 } = err;
//     if (!err.message) err.message = 'Oh No, Something Went Wrong!'
//     res.status(statusCode).render('error', { err })
// })

console.log("ENV: ", app.get('env'));
module.exports= app;