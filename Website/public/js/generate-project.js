
let generationCount = 0;
 
async function generateProject() {
  document.getElementById("loaderBar").style.display="block";

  const mat = document.getElementById("mainmat").textContent;
  const materialsArray = mat.split(",").map(m => m.trim());
  
  console.log(mat);
  const response = await fetch("/generate-project/generate-another", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ materials: materialsArray }),
  });

  if (response.redirected) {
    window.location.href = response.url;
  } else {
    alert("Failed to generate project page.");
  }
}

// ai-assist.js - Add this to your project's public/js directory
// Make sure to include it in your HTML before the closing </body> tag

// Project URL format: /projects/:projectId
const projectId = window.location.pathname.split('/').pop();

// Track which step's AI assistant is currently active
let activeAssistantId = null;

/**
 * Opens the AI Assistant for a specific step
 * @param {number} stepIndex - The index of the step
 */
function openAIAssistant(stepIndex) {
  // Get the step element and its content
  const step = document.querySelectorAll('.step')[stepIndex];
  const stepTitle = step.querySelector('.step-title').textContent;
  const stepContent = step.querySelector('.step-content').textContent;
  
  // Get the AI assistant elements
  const aiExpansion = step.querySelector('.ai-assistant-expansion');
  const aiText = document.getElementById(`ai-text-${stepIndex}`);
  
  // Toggle the active state
  if (aiExpansion.classList.contains('active')) {
    aiExpansion.classList.remove('active');
    return;
  }
  
  // Show loading state
  aiExpansion.classList.add('active');
  aiText.textContent = 'Analyzing this step...';
  
  // If there's another active assistant, close it
  if (activeAssistantId !== null && activeAssistantId !== stepIndex) {
    const previousExpansion = document.querySelectorAll('.ai-assistant-expansion')[activeAssistantId];
    previousExpansion.classList.remove('active');
  }
  
  // Set this as the active assistant
  activeAssistantId = stepIndex;
  
  // Get the main project image
  const projectImage = document.querySelector('.mySlides img').src;
  
  // Call the API through your backend
  callVisionAPI(stepTitle, stepContent, projectImage, stepIndex);
}

/**
 * Calls the server endpoint that will interact with OpenAI's Vision API
 * @param {string} title - The step title
 * @param {string} content - The step instructions
 * @param {string} imageUrl - URL of the project image
 * @param {number} stepIndex - Index of the step being analyzed
 */
async function callVisionAPI(title, content, imageUrl, stepIndex) {
  try {
    // Show loading bar animation
    const loaderBar = document.createElement('div');
    loaderBar.className = 'loader-bar';
    loaderBar.style.display = 'block';

    // Access aiText directly without redefining
    const aiText = document.getElementById(`ai-text-${stepIndex}`);
    aiText.textContent = 'Analyzing this step...';
    aiText.parentNode.appendChild(loaderBar);

    const pathSegments = window.location.pathname.split('/');
    const projectId = pathSegments[pathSegments.length - 1];

    if (!projectId) {
      throw new Error("Project ID not found in URL");
    }
    
    const response = await fetch(`/projects/${projectId}/ai-assist`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ 
        projectId,
        stepIndex,
        title, 
        content, 
        imageUrl 
      })
    });
    
    if (!response.ok) {
      throw new Error('API request failed');
    }
    
    const data = await response.json();
    
    // Display the AI response with typing effect
    typeResponse(aiText, data.response);

    // Remove the loader bar after completion
    loaderBar.remove();
  } catch (error) {
    console.error('Error calling AI assistant:', error);
    const aiText = document.getElementById(`ai-text-${stepIndex}`);
    aiText.textContent = 'Sorry, I encountered an issue analyzing this step. Please try again.';
  }
}


/**
 * Types out the response with an animated effect
 * @param {HTMLElement} element - The element to update
 * @param {string} text - The text to display
 */
function typeResponse(element, text) {
  let index = 0;
  element.textContent = '';
  
  // Create typing effect
  const typingInterval = setInterval(() => {
    if (index < text.length) {
      element.textContent += text.charAt(index);
      index++;
    } else {
      clearInterval(typingInterval);
    }
  }, 15); // Speed of typing
}

// Update the onclick handler in your HTML
document.addEventListener('DOMContentLoaded', function() {
  const aiButtons = document.querySelectorAll('.ai-assist');
  
  aiButtons.forEach((button, index) => {
    button.onclick = function() {
      openAIAssistant(index);
    };
  });
});


async function generateProduct() {
  const category=document.getElementById("category").innerText;
  const projectId=document.getElementById("projectId").innerText;
  console.log(projectId)
  // Step 2: Call backend to generate full project
  const response = await fetch("/generate-product/generate-another", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({projectId}),
    
  });

  // const data = await response.json();

  // // Step 3: Populate frontend
  // document.getElementById("project-name").textContent = data.name;
  // document.getElementById("category").textContent = data.category;
  // document.getElementById("project-image").src = data.image;
  
  // // Update materials
  // const matList = document.getElementById("generated-materials");
  // matList.innerHTML = data.extractedMaterials.map(m => `<li>${m}</li>`).join("");
  
  // // Update instructions
  // const instructionsList = document.getElementById("instructions");
  // instructionsList.innerHTML = data.instructions.map(i => `<li>${i}</li>`).join("");

  // // Update URL without reload
  // generationCount++;
  // const newURL = generationCount === 1 
  //   ? "/generate-project/1" 
  //   : `/generate-project/${generationCount}`;
  // window.history.pushState({}, "", newURL);
}

  