function toggleSettings() {
  const settings = document.getElementById("settingsPanel");
  const main = document.getElementById("mainArea");

  settings.classList.toggle("hidden");
  main.classList.toggle("full-width");

}

function showGreenToast(message) {
  const toast = document.getElementById('toastGreen');
  toast.textContent = message;
  toast.classList.add('show');
  setTimeout(() => {
    toast.classList.remove('show');
  }, 3000);
}

function showRedToast(message) {
  const toast = document.getElementById('toastRed');
  toast.textContent = message;
  toast.classList.add('show');
  setTimeout(() => {
    toast.classList.remove('show');
  }, 3000);
}

const fileInput = document.getElementById("fileInput");
const imagePreviews = document.getElementById("imagePreviews");
let selectedFiles = [];

// ✅ Track selected files and show previews
fileInput.addEventListener("change", function () {
  const newFiles = Array.from(this.files);
  const allowedTypes = ["image/jpeg", "image/png", "image/jpg", "image/webp"];

  newFiles.forEach((file) => {
    if (!allowedTypes.includes(file.type)) {
      showRedToast("Only image formats are accepted (JPEG, PNG, WEBP)")
      return;
    }

    if (selectedFiles.some(f => f.name === file.name && f.size === file.size)) return;

    selectedFiles.push(file);

    const reader = new FileReader();
    reader.onload = function (e) {
      const container = document.createElement("div");
      container.classList.add("preview-container");

      const img = document.createElement("img");
      img.src = e.target.result;
      container.appendChild(img);

      const deleteBtn = document.createElement("button");
      deleteBtn.classList.add("delete-btn");
      deleteBtn.innerHTML = "&times;";
      deleteBtn.onclick = () => {
        imagePreviews.removeChild(container);
        selectedFiles = selectedFiles.filter(f => f !== file);
      };

      container.appendChild(deleteBtn);
      imagePreviews.appendChild(container);
    };

    reader.readAsDataURL(file);
  });

  this.value = ""; // ✅ Reset input safely after tracking files
});


function moveGeneratedToExampleGallery() {
  const exampleGallery = document.getElementById("exampleGallery");

  // Add current generated projects to example-gallery
  currentGeneratedProjects.forEach(card => {
    exampleGallery.insertBefore(card, exampleGallery.firstChild);
  });

  // Ensure only the last 3 projects are shown in example-gallery
  while (exampleGallery.children.length > 3) {
    exampleGallery.removeChild(exampleGallery.lastChild);
  }

  // Clear the current generated projects for the next generation
  currentGeneratedProjects = [];
}

let currentGeneratedProjects = [];

// ✅ Submit handler using selectedFiles
document.getElementById("uploadForm").addEventListener("submit", async function (e) {
  e.preventDefault();
  
  currentUser=document.getElementById("currUser").innerHTML;


  const form = this;
  const formData = new FormData(form);
  const similarity = document.getElementById("similarity").value;
  const numberOfImages = parseInt(document.getElementById("numberOfImages").value);
  const newProjectsGrid = document.getElementById("newProjectsGrid");

  if(!currentUser){
    const response = await fetch("/upload/generate", {
      method: "POST",
      body: formData,
      headers: {
        "Accept": "application/json" // Explicitly set to expect JSON
      }
    });
    const responseData = await response.json();
    if (responseData.redirectUrl) {
      window.location.href = responseData.redirectUrl;
      return;
    }
}

  // Append selected files manually
  selectedFiles.forEach(file => {
    formData.append("images", file);
  });

  if(selectedFiles.length===0){
    showRedToast("No uploaded images")
    return
  }

  moveGeneratedToExampleGallery();

  // Clear existing content
  newProjectsGrid.innerHTML = "";

  const placeholders = [];
  for (let i = 0; i < numberOfImages; i++) {
    const placeholder = document.createElement("div");
    placeholder.className = "placeholder";
    placeholder.innerHTML = "<span>Innovive</span>";
    newProjectsGrid.appendChild(placeholder);
    placeholders.push(placeholder);
  }

  
  // Append these values to the FormData object
  formData.append("numberOfImages", numberOfImages);
  formData.append("similarity", similarity);

  const response = await fetch("/upload/generate", {
    method: "POST",
    body: formData,
  });

  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  let buffer = "";
  let index = 0;

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;

    buffer += decoder.decode(value, { stream: true });
    let lines = buffer.split("\n");
    buffer = lines.pop(); // keep incomplete part

    for (const line of lines) {
      if (!line.trim()) continue;

      try {
        const data = JSON.parse(line);
        const card = document.createElement('div');
        card.className = 'project-card';
        card.innerHTML = `
        <img src="${data.image}" class="project-image" alt="${data.name}" />
    
        <div class="icon-buttons">
          <button class="icon-btn delete" title="Delete Project" onclick="deleteProject('${data._id}', this)">
                <i class="fas fa-trash-alt"></i>
          </button>
          ${data.shared ? `
            <div class="icon-btn shared-indicator" title="Already Shared">
              <i class="fas fa-check"></i>
            </div>
          ` : `
            <button class="icon-btn" title="Share Project" onclick="shareProject('${data._id}', this)">
              <i class="fas fa-share-alt"></i>
            </button>
          `}
          
          <button class="icon-btn" title="Share + Handmade" onclick="openHandmadeModal('${data._id}')">
            <i class="fas fa-hand-holding-heart"></i>
          </button>
        </div>
    
        <div class="overlay">
          <button class="show-info-btn" type="button" onclick="window.location.href='/projects/${data._id}'">Show Info</button>
        </div>
    
        <div class="project-name">${data.name}</div>
      `;
        newProjectsGrid.replaceChild(card, placeholders[index]);
        currentGeneratedProjects.push(card);
        index++;
      } catch (err) {
        console.error("Failed to parse chunk:", line, err.message);
      }
    }
  }
});


//modal functions

function shareProject(projectId, btn) {
  projectToShare = projectId;
  buttonToRemove = btn;
  document.getElementById('confirmModal').style.display = 'flex';
}

function closeConfirmModal() {
  document.getElementById('confirmModal').style.display = 'none';
  projectToShare = null;
  buttonToRemove = null;
}

document.getElementById('confirmShareBtn').addEventListener('click', () => {
  if (!projectToShare) return;

  fetch(`/upload/share/${projectToShare}`, {
    method: 'POST'
  })
  .then(res => {
    if (!res.ok) throw new Error('Share failed');
    return res.json();
  })
  .then(data => {
    closeConfirmModal();

    // Remove the share button
    if (buttonToRemove) {
      buttonToRemove.remove(); // removes the actual button from DOM
    }

    showGreenToast('Project shared! You earned 2 points 🎉');
  })
  .catch(err => {
    closeConfirmModal();
    showRedToast('Something went wrong while sharing.');
    console.error(err);
  });
});






///////////////////////////////////

 // ========== Modal Control Functions ==========
 let projectToUploadHandmade = null;

function openHandmadeModal(projectId) {
console.log("Selected Project ID:", projectId); // Debug line
projectToUploadHandmade = projectId;
document.getElementById('handmadeModal').style.display = 'flex';
}

function closeHandmadeModal() {
document.getElementById('handmadeModal').style.display = 'none';
}

// ========== Image Preview and Path Display ==========
function showSelectedImage(input) {
const file = input.files[0];
if (file) {
  document.getElementById('selectedFileName').textContent = file.name;
  document.getElementById('imagePath').textContent = `Selected Image Path: ${file.name}`;

  const reader = new FileReader();
  reader.onload = function(e) {
    document.getElementById('imagePreview').style.display = 'block';
    document.getElementById('previewImage').src = e.target.result;
  };
  reader.readAsDataURL(file);
} else {
  removeSelectedImage();
}
}

// ========== Upload Handmade Image Logic ==========
document.getElementById('handmadeForm').addEventListener('submit', async (e) => {
e.preventDefault();
if (!projectToUploadHandmade) {
  showRedToast("No project selected.");
  return;
}

// Close modal immediately for better UX
closeHandmadeModal();
showGreenToast('Uploading...');

const formData = new FormData(document.getElementById('handmadeForm'));
try {
  const response = await fetch(`/upload/handmade/${projectToUploadHandmade}`, {
    method: 'POST',
    body: formData
  });

  if (!response.ok) throw new Error('Upload failed');
  const data = await response.json();
  showGreenToast('Handmade image uploaded successfully! 🎉 Waiting for the admin to review....');
  
  // Reset after successful upload
  resetHandmadeModal();
} catch (err) {
  showRedToast('Failed to upload handmade image.');
  console.error(err);
}
});

// Function to reset modal without closing it
function resetHandmadeModal() {
projectToUploadHandmade = null;
document.getElementById('handmadeForm').reset();
document.getElementById('selectedFileName').textContent = "Choose File";
document.getElementById('imagePath').textContent = "";
document.getElementById('imagePreview').style.display = 'none';
document.getElementById('previewImage').src = "";
}

// Function to remove the selected image
function removeSelectedImage() {
resetHandmadeModal();
}


async function deleteProject(projectId, deleteButton) {
  // Confirm deletion
  if (!confirm("Are you sure you want to delete this project?")) return;

  // Get the card element
  const projectCard = deleteButton.closest(".project-card");

  // Add deleting class for smooth transition
  projectCard.classList.add("deleting");

  try {
    // Send DELETE request to the server
    const response = await fetch(`/upload/delete/${projectId}`, {
      method: "DELETE",
      headers: {
        "Content-Type": "application/json"
      }
    });

    if (response.ok) {
      // Remove the project card from the DOM after animation
      setTimeout(() => {
        projectCard.remove();
      }, 300); // Match the CSS transition duration
    } else {
      alert("Failed to delete the project. Please try again.");
      projectCard.classList.remove("deleting");
    }
  } catch (error) {
    console.error("Error deleting project:", error);
    alert("An error occurred. Please try again.");
    projectCard.classList.remove("deleting");
  }
}