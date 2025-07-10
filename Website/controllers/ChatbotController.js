// controllers/chatbotController.js
const axios = require("axios");
const mongoose = require("mongoose");
const fs = require("fs");
const path = require("path");
const MaterialClassifier = require("./MaterialClassifier");
const ProjectGenerator = require("./ProjectGenerator");
const ProductGenerator = require("./productGenerator");
const GeneratedProject = require("../models/Project");
const User = require("../models/User");
const AI_USER_ID = process.env.AI_USER_ID;


const knowledge = fs.readFileSync(
    path.join(__dirname, "../rag/knowledgebase.txt"),
    "utf8"
);


const pendingProject = {
    project: null,
    waitingForSteps: false,
    waitingForStepInquiries: false,
};

const lastUploaded = {
    lastBase64: null,
    lastMaterials: null
}

const pendingProduct = {
    material: null,
    category: null,
};

const MATERIALS = [
    "wood", "metal", "glass", "plastic", "fabric", "cardboard",
    "aluminum", "steel", "rubber", "paper", "ceramic", "leather"
];

const extractMaterialsFromMessage = (message) => {
    const lowered = message.toLowerCase();
    const detected = MATERIALS.find(material => lowered.includes(material));
    console.log("Material detected:", detected);
    return detected || null;
};

// Simple category extractor
const CATEGORIES = [
    'furniture', 'storage', 'office', 'organizer', 'decor',
    'kitchenware', 'lighting', 'upholstery'
];


const extractCategoryFromMessage = (message) => {
    console.log("Message is:", message);
    const lowered = message.toLowerCase();
    const detected = CATEGORIES.find(category => lowered.includes(category));
    console.log("Searching for category....", detected)
    return detected || null;
};




const getIntent = async (userMessage) => {
    const systemPrompt = `
You are a smart routing assistant. Given a user message, determine their intent and reply with ONE of the following values ONLY (no explanation):

${knowledge}

- info
- classify
- generate_project
- generate_product

Examples:
User: What can I make with this plastic bottle?
→ generate_project

User: Give me a product design using wood.
→ generate_product

User: What's this material in the image?
→ classify

`;
    try {
        const response = await axios.post(
            "https://api.openai.com/v1/chat/completions",
            {
                model: "gpt-4",
                messages: [
                    { role: "system", content: systemPrompt },
                    { role: "user", content: userMessage },
                ],
                temperature: 0,
            },
            {
                headers: {
                    Authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
                },
            }
        );

        return response.data.choices[0].message.content.trim().toLowerCase();

    } catch (err) {
        console.log("Error in getting intention:", err);
    }


};




// Main intent handlers
const handleInfoIntent = async (req, res) => {
    const { message } = req.body;

    const completion = await axios.post("https://api.openai.com/v1/chat/completions", {
        model: "gpt-4",
        messages: [
            { role: "system", content: `You are a helpful assistant. Use the information below to answer user questions about Innovive.\n\n${knowledge}` },
            { role: "user", content: message },
        ],
        temperature: 0.7,
    }, {
        headers: { Authorization: `Bearer ${process.env.OPENAI_API_KEY}` },
    });

    const infoAnswer = completion.data.choices[0].message.content.trim();
    return res.json({ text: infoAnswer });
};




const handleClassifyIntent = async (req, res) => {
    const { fileBase64 } = req.body;

    const classifier = new MaterialClassifier(null, fileBase64);
    await classifier.classify();
    const materials = classifier.getResults();

    // Save for future use
    pendingProject.lastBase64 = fileBase64;
    pendingProject.lastMaterials = materials;

    return res.json({ text: `Material/s: ${materials.join(", ") || "Unknown"}` });
};


async function saveGeneratedProject(project, req) {
    try {
        let user = req.user;

        if (!user) {
            // Load AI user by ID from env
            const aiUser = await User.findById(process.env.AI_USER_ID);
            if (!aiUser) throw new Error("AI user not found");
            user = aiUser;
        }

        // Ensure the materials and instructions are properly formatted as objects
        const formattedMaterials = Array.isArray(project.materials) && project.materials.length > 0
            ? project.materials.map(material => {
                return typeof material === "string"
                    ? { title: material, description: "No description provided." }
                    : material;
            })
            : [];

        const formattedInstructions = Array.isArray(project.instructions) && project.instructions.length > 0
            ? project.instructions.map(step => {
                return typeof step === "string"
                    ? { title: step, description: "No description provided." }
                    : step;
            })
            : [];

        const projectData = {
            name: project.name,
            image: project.image,
            level: project.level,
            materials: formattedMaterials,
            mainmaterials: project.mainmaterials,
            instructions: formattedInstructions,
            user: user,
            shared: false,
        };

        const savedProject = await GeneratedProject.create(projectData);
        console.log("✅ Project saved successfully:", savedProject._id);
        return savedProject;

    } catch (err) {
        console.error("❌ Failed to save project:", err.message);
        throw err;
    }
}



const handleGenerateProjectIntent = async (req, res) => {
    const { fileBase64 } = req.body;

    let materials = [];
    if (fileBase64) {
        const classifier = new MaterialClassifier(null, fileBase64);
        await classifier.classify();
        materials = classifier.getResults();

        lastUploaded.lastBase64 = fileBase64;
        lastUploaded.lastMaterials = materials;
    }

    const generator = new ProjectGenerator(materials, fileBase64);
    const project = await generator.build();

    pendingProject.project = project;
    pendingProject.waitingForSteps = true;

    await saveGeneratedProject(project, req);

    const formattedMaterials = project.materials
        .map(mat => `- ${mat.title}: ${mat.description}`)
        .join("\n");


    const reply = `
🛠️ Project Name: ${project.name} (Difficulty: ${project.level})
📦 Materials:
${formattedMaterials || "No materials specified."}

📋 Would you like to see the steps for this project? (yes/no)`.trim();

    return res.json({ text: reply, image: project.image });
};

const handleRegenerateProjectIntent = async (req, res) => {
    if (!lastUploaded.fileBase64 || !lastUploaded.materials.length) {
        return res.json({ text: "❗ Sorry, I don't have your last upload to regenerate from. Please upload a new image." });
    }

    const generator = new ProjectGenerator(lastUploaded.materials, lastUploaded.fileBase64);
    const project = await generator.build();

    pendingProject.project = project;
    pendingProject.waitingForSteps = true;

    await saveGeneratedProject(project, req);

    const formattedMaterials = project.materials
        .map(mat => `- ${mat.title}: ${mat.description}`)
        .join("\n");
    
    const time = null;
    if(project.level === "Beginner"){
        time = "1-2 hours";
    }
    else if(project.level === "Intermediate"){
        time = "2-3 hours";
    }
    else{
        time = "3-4 hours";
    }

    const reply = `
🛠️ Project Name: ${project.name} 
🛠️ Difficulty: ${project.level} Estimated Time: ${time}
📦 Materials:
${formattedMaterials || "No materials specified."}

📋 Would you like to see the steps for this project? (yes/no)`.trim();

    return res.json({ text: reply, image: project.image });
};


const handleConfirmStepsIntent = async (req, res) => {
    if (pendingProject.project) {
        const steps = pendingProject.project.instructions;
        const formattedSteps = steps
        .map((step, idx) => `${idx + 1}. ${step.title}: ${step.description}`)
        .join("\n");
        pendingProject.waitingForStepInquiries = true;

        return res.json({
            text: `📋 Here are the steps:\n\n${formattedSteps}\n\n
            🤔 Need help? You can ask me to clarify any step!`  });
    } else {
        return res.json({ text: "No project available currently to show steps for." });
    }
};


const handleStepInquiryIntent = async (req, res) => {
    const { message } = req.body;

    if (!pendingProject.project) {
        return res.json({ text: "Please request a project first before asking about steps." });
    }

    const lower = message.toLowerCase();
    const hasStepKeyword = /step\s*\d+|clarify\s*\d+|\btwo\b|\bthree\b|\bfour\b|\bfive\b|\bsix\b|\bseven\b|\beight\b|\bnine\b|\bone\b/.test(lower);

    if (!hasStepKeyword) {
        pendingProject.waitingForStepInquiries = false;
        return res.json({ text: "❌ I'm not sure which step you're referring to. Try saying something like 'clarify step 2' or 'step four'." });
    }

    if (!pendingProject.waitingForStepInquiries) {
        return res.json({ text: "Please ask to see the steps before requesting clarification." });
    }

    const steps = pendingProject.project.instructions;
    const stepRegex = /(?:step\s*)?(\d+)/i;
    const match = message.match(stepRegex);

    if (match) {
        const stepNumber = parseInt(match[1], 10);

        if (stepNumber >= 1 && stepNumber <= steps.length) {
            const stepText = steps[stepNumber - 1];
            const projectName = pendingProject.project.name;

            const formattedSteps = steps
                .map((step, idx) => `${idx + 1}. ${step.title}: ${step.description}`)
                .join("\n");

            const clarificationPrompt = `
  You are an expert DIY assistant.
  
  The user is working on the project: "${projectName}".
  
  Here are the project steps:
  ${steps.map((s, i) => `${i + 1}. ${s}`).join("\n")}
  
  The user wants clarification about Step ${stepNumber}:
  "${formattedSteps}"
  
  🔵 Clarify this step in a simple, friendly, and detailed way.
  ✅ If helpful, give tips, warnings, or examples.
  ✅ Limit explanation to 3-5 sentences.
  `;

            try {
                const aiResponse = await axios.post(
                    "https://api.openai.com/v1/chat/completions",
                    {
                        model: "gpt-4",
                        messages: [{ role: "system", content: clarificationPrompt }],
                        temperature: 0.7,
                    },
                    {
                        headers: {
                            Authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
                        },
                    }
                );

                const detailedExplanation = aiResponse.data.choices[0].message.content.trim();
                return res.json({
                    text: `🔍 Step ${stepNumber} clarified:\n${detailedExplanation}\n\n💬 You can ask about another step if you like.`,
                });
            } catch (error) {
                console.error("Failed to clarify step:", error.message);
                return res.json({ text: `🔍 Step ${stepNumber}: ${stepText}` });
            }
        } else {
            return res.json({ text: `❌ Invalid step number. This project has ${steps.length} steps.` });
        }
    } else {
        return res.json({ text: "❌ Please specify the step number (e.g., 'step 3', 'clarify step four')." });
    }
};




const handleGenerateProductIntent = async (req, res) => {
    const { message } = req.body;

    // 🔵 CASE 1: User was already asked for category
    if (pendingProduct.waitingForCategory && pendingProduct.material) {
        const category = extractCategoryFromMessage(message);

        if (!category) {
            return res.json({
                text: `❗ Please specify a valid category (e.g., furniture, lighting, decor).`,
            });
        }

        const generator = new ProductGenerator(pendingProduct.material, category);
        const product = await generator.build();

        // Clear pending
        pendingProduct.waitingForCategory = false;
        pendingProduct.material = null;

        let reply = `🛠️ Product Name: ${product.name}\n`;

        if (product.measurements?.length > 0) {
            reply += `\n📐 Measurements:\n${product.measurements.join("\n")}\n`;
        }

        if (product.additionalMaterials?.length > 0) {
            reply += `\n📦 Additional Materials:\n${product.additionalMaterials.join("\n")}\n`;
        }

        return res.json({ text: reply.trim(), image: product.image });
    }

    // 🔵 CASE 2: Fresh message
    const materials = extractMaterialsFromMessage(message);
    const category = extractCategoryFromMessage(message);

    if (materials && category) {
        // User provided both material and category in one message ✅
        const generator = new ProductGenerator(materials, category);
        const product = await generator.build();

        let reply = `🛠️ Product Name: ${product.name}\n`;

        if (product.measurements?.length > 0) {
            reply += `\n📐 Measurements:\n${product.measurements.join("\n")}\n`;
        }

        if (product.additionalMaterials?.length > 0) {
            reply += `\n📦 Additional Materials:\n${product.additionalMaterials.join("\n")}\n`;
        }

        return res.json({ text: reply.trim(), image: product.image });
    }

    if (materials && !category) {
        // User provided only material — ask for category 🟡
        pendingProduct.material = materials;
        pendingProduct.waitingForCategory = true;

        return res.json({
            text: `🛠️ Great! You selected ${materials}.\nWhat type of product would you like to design? (e.g., furniture, lighting, decor, office)`,
        });
    }

    // 🔴 If neither material nor category detected
    return res.json({
        text: `❗ I couldn't detect a material. Please tell me which material you want to use (e.g., wood, glass, metal, fabric, plastic).`,
    });
};

module.exports = {
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
    lastUploaded
};
