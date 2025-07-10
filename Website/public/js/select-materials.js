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
  
  // ✅ Submit handler 
  document.getElementById("uploadForm").addEventListener("submit", async function (e) {
    e.preventDefault();

    const selectedMaterials = Array.from(document.querySelectorAll('input[name="materials"]:checked')).map(input => input.value);
    const category = document.getElementById("category").value;
    const numberOfImages = document.getElementById("numberOfImages").value;

    if (selectedMaterials.length === 0) {
      showRedToast("Please select at least one material.");
      return;
    }
    currentUser=document.getElementById("currUser").innerHTML;
  
  
    const form = this;
    const formData = new FormData(form);

    // formData.delete("materials");
    // formData.delete("category");
    // formData.delete("numberOfImages");

    formData.append("materials", JSON.stringify(selectedMaterials));
    formData.append("category", category);
    formData.append("numberOfImages", numberOfImages);

    for (const [key, value] of formData.entries()) {
      console.log(`${key}: ${value}`);
    }

    console.log(category)
    console.log(numberOfImages)
    console.log(JSON.stringify(selectedMaterials))

    const newProjectsGrid = document.getElementById("newProjectsGrid");
  
    if(!currentUser){
      const response = await fetch("/select-materials/generate", {
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
  
    console.log("sending request");
    for (const [key, value] of formData.entries()) {
      console.log(`${key}: ${value}`);
    }

    const response = await fetch("/select-materials/generate", {
      method: "POST",
      body: formData,
      headers: {
        "Accept": "application/json" // Explicitly set to expect JSON
      }
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
          
          </div>
      
          <div class="overlay">
            <button class="show-info-btn" type="button" onclick="window.location.href='/product/${data._id}'">Show Info</button>
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
  