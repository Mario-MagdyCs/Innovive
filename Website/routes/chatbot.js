const express = require('express');
const router = express.Router();
const {
    getIntent,
    handleInfoIntent,
    handleClassifyIntent,
    handleGenerateProjectIntent,
    handleConfirmStepsIntent,
    handleStepInquiryIntent,
    handleRegenerateProjectIntent,
    handleGenerateProductIntent,
    pendingProject,
    pendingProduct,
    lastUploaded,
} = require('../controllers/ChatbotController');

router.get("/", (req, res) => res.render("chatbot", { currentUser: req.user }));

router.post("/message", async (req, res) => {
    const { message } = req.body;
    const lowered = message.toLowerCase().trim();

    // FIRST: Check for greetings ONLY if the message is simple
    const helpTriggers = ["hi", "hello", "hey", "help", "what can i do"];

    // If the entire message is JUST a greeting → immediately welcome
    if (helpTriggers.includes(lowered)) {
        return res.json({
            text: `👋 Welcome to Innovive!
      
I'm your AI assistant for both creative DIY and industrial upcycling. 
Here are examples of what you can ask me:

🧰 Enthusiast Users: "Give me a diy project using (name a waste material/ upload a photo)"
  e.g., plastic bottle, glass jar, cardboard box...

🏭 Industrial Users: "Design a table using recycled metal"

I can also explain Innovive's main features if you want!`
        });
    }


    // SECOND: Check if user is confirming a pending project or product
    //User confirmed getting project steps
    if (pendingProject.waitingForSteps && lowered.includes("yes")) {
        pendingProject.waitingForSteps = false;
        pendingProject.waitingForStepInquiries = true;
        return await handleConfirmStepsIntent(req, res);
    }

    //User requests step clarification
    if (pendingProject.waitingForStepInquiries && (lowered.includes("step") || /\d/.test(lowered))) {
        return await handleStepInquiryIntent(req, res);
    }

    // Pending industrial product category
    if (pendingProduct.waitingForCategory && pendingProduct.material) {
        return await handleGenerateProductIntent(req, res);
    }

    if (lowered.includes("generate another") || lowered.includes("create another") || (lowered.includes("another") && lowered.includes("project")) || (lowered.includes("another") && lowered.includes("diy"))) {
        return await handleRegenerateProjectIntent(req, res);
    }

 
    // THIRD: Process normally by detecting intent
    console.log("Evaluating intent....")

    const intent = await getIntent(message);
    console.log("Intent is: ", intent);

    if (intent === "info") return handleInfoIntent(req, res);
    if (intent === "classify") return handleClassifyIntent(req, res);
    if (intent === "generate_project") return handleGenerateProjectIntent(req, res);
    if (intent === "generate_product") return handleGenerateProductIntent(req, res);
    if (intent === "filter") return handleFilterIntent(req, res);
    if (intent === "extract") return handleExtractIntent(req, res);

    return res.json({ text: "❓ Sorry, I didn't fully understand your request." });
});

module.exports = router;
