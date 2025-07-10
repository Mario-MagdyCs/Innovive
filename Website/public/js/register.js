document.getElementById("waste-form")?.addEventListener("submit", async function(event) {
    event.preventDefault();
    let selectedWaste = Array.from(document.querySelectorAll('input[name="waste"]:checked')).map(e => e.value);

    let other = document.querySelector('input[name="waste_other"]').value.trim();
    if (other) selectedWaste.push(other);

    try {
        const response = await fetch('/register-enthusiast/step3', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ materials: selectedWaste })
        });

        const result = await response.json();
        console.log('Server response:', result);

        window.location.href = "/register-enthusiast/step4";
    } catch (err) {
        console.error('Error submitting form:', err);
        alert("Failed to submit. Please try again.");
    }
});


document.getElementById("projects-form")?.addEventListener("submit", async function(event) {
    event.preventDefault();
    let selectedCategories = Array.from(document.querySelectorAll('input[name="projects"]:checked')).map(e => e.value);

    let other = document.querySelector('input[name="projects_other"]').value.trim();
    if (other) selectedCategories.push(other);

    try {
        const response = await fetch('/register-enthusiast/step4', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ categories: selectedCategories })
        });

        const result = await response.json();
        console.log('Server response:', result);

        window.location.href = "/register-enthusiast/done";
    } catch (err) {
        console.error('Error submitting form:', err);
        alert("Failed to submit. Please try again.");
    }
});

document.getElementById("industry-form")?.addEventListener("submit", async function(event) {
    event.preventDefault();
    let selectedIndustryCategories= Array.from(document.querySelectorAll('input[name="industry"]:checked')).map(e => e.value);

    let other = document.querySelector('input[name="industry_other"]').value.trim();
    if (other) selectedIndustryCategories.push(other);

    try {
        const response = await fetch('/register-industrial/step3', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ industry_categories: selectedIndustryCategories })
        });

        const result = await response.json();
        console.log('Server response:', result);

        window.location.href = "/register-industrial/step4";
    } catch (err) {
        console.error('Error submitting form:', err);
        alert("Failed to submit. Please try again.");
    }
});

document.getElementById("manufacturing-form")?.addEventListener("submit", async function(event) {
    event.preventDefault();
    let selectedProcesses= Array.from(document.querySelectorAll('input[name="process"]:checked')).map(e => e.value);

    let other = document.querySelector('input[name="process_other"]').value.trim();
    if (other) selectedProcesses.push(other);

    try {
        const response = await fetch('/register-industrial/step4', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ processes: selectedProcesses })
        });

        const result = await response.json();
        console.log('Server response:', result);

        window.location.href = "/register-industrial/step5";
    } catch (err) {
        console.error('Error submitting form:', err);
        alert("Failed to submit. Please try again.");
    }
});


document.getElementById("automation-form")?.addEventListener("submit", async function(event) {
    event.preventDefault();
    let selectedAutomation = document.querySelector('input[name="automation"]:checked').value;

    try {
        const response = await fetch('/register-industrial/step5', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ automation: selectedAutomation })
        });

        const result = await response.json();
        console.log('Server response:', result);

        window.location.href = "/register-industrial/step6";
    } catch (err) {
        console.error('Error submitting form:', err);
        alert("Failed to submit. Please try again.");
    }
});

document.getElementById("materials-form")?.addEventListener("submit", async function(event) {
    event.preventDefault();
    let selectedMaterials = Array.from(document.querySelectorAll('input[name="materials"]:checked')).map(e => e.value);

    let other = document.querySelector('input[name="materials_other"]').value.trim();
    if (other) selectedMaterials.push(other);

    try {
        const response = await fetch('/register-industrial/step6', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ materials: selectedMaterials })
        });

        const result = await response.json();
        console.log('Server response:', result);

        window.location.href = "/register-industrial/done";
    } catch (err) {
        console.error('Error submitting form:', err);
        alert("Failed to submit. Please try again.");
    }
});