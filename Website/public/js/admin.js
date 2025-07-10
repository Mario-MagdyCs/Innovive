document.querySelectorAll('.change').forEach(change => {
    const value = parseFloat(change.textContent);
    if (value < 0) {
        change.style.color = "#e74c3c"; // Red for negative
    } else {
        change.style.color = "#27ae60"; // Green for positive
    }
});
// //////////////////////////////////////////////////////////////////////////////////
document.addEventListener("DOMContentLoaded", function () {
  const chartContainer = document.getElementById('weekly-chart');
  const projectData = JSON.parse(chartContainer.getAttribute('data-weekly-projects'));
  const ctx = document.getElementById('weeklyProjectsChart').getContext('2d');

  const avgValue = (projectData.reduce((a, b) => a + b, 0) / projectData.length).toFixed(1);

  const weeklyProjectsChart = new Chart(ctx, {
    type: 'bar',
    data: {
      labels: ['S', 'M', 'T', 'W', 'T', 'F', 'S'],
      datasets: [{
        label: 'Projects Completed',
        data: projectData,
        backgroundColor: '#27ae60',
        borderRadius: 8,
        barThickness: 35
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      scales: {
        y: {
          beginAtZero: true,
          grid: { color: '#3a3b42' },
          ticks: { color: '#f0f0f0', font: { size: 12 } }
        },
        x: {
          grid: { color: '#3a3b42' },
          ticks: { color: '#f0f0f0', font: { size: 14 } }
        }
      },
      plugins: {
        legend: { display: false },
        annotation: {
          annotations: {
            avgLine: {
              type: 'line',
              yMin: avgValue,
              yMax: avgValue,
              borderColor: '#27ae60',
              borderWidth: 2,
              borderDash: [6, 4],
              label: {
                display: true,
                content: 'avg',
                position: 'end',
                color: '#27ae60',
                backgroundColor: 'transparent',
                font: { size: 12, weight: 'bold' }
              }
            }
          }
        }
      }
    }
  });
});


/////////////////////////////////////////////////////////


document.addEventListener("DOMContentLoaded", function() {
  document.querySelectorAll('.popularity-fill').forEach(element => {
    const width = element.getAttribute('data-width');
    element.style.width = `${width}%`;
  });
});
// /////////////////////////////////////////////////////////////////


 document.addEventListener("DOMContentLoaded", fetchPendingPosts);

  async function fetchPendingPosts() {
    try {
      const response = await fetch('/admin-pending/data');
      const data = await response.json();
      displayPendingPosts(data.projects);
    } catch (err) {
      console.error("Failed to fetch pending posts:", err);
    }
  }

  function displayPendingPosts(pendingPosts) {
    const container = document.getElementById("pendingPostsContainer");
    container.innerHTML = "";

    pendingPosts.forEach((post, index) => {
      const postCard = `
        <div class="post-card">
          <img src="${post.uploads[0]?.imagePath || '/default-image.png'}" alt="Post Image">
          <div class="post-info">
            <span class="user-name">By: ${post.user.fullName}</span>
            <div class="actions">
              <button class="accept-btn" onclick="acceptPost('${post._id}', ${index})">Accept</button>
              <button class="reject-btn" onclick="rejectPost('${post._id}', ${index})">Reject</button>
            </div>
          </div>
        </div>
      `;
      container.insertAdjacentHTML("beforeend", postCard);
    });
  }

  async function acceptPost(projectId, index) {
    try {
      const response = await fetch(`/admin-pending/handmade/accept/${projectId}/${index}`, {
        method: 'POST'
      });
      if (!response.ok) throw new Error("Failed to accept image");
      alert(`Image accepted successfully! User awarded 5 points.`);
      fetchPendingPosts();
    } catch (err) {
      alert("Error: " + err.message);
    }
  }

  async function rejectPost(projectId, index) {
    try {
      const response = await fetch(`/admin-pending/handmade/reject/${projectId}/${index}`, {
        method: 'POST'
      });
      if (!response.ok) throw new Error("Failed to reject image");
      alert("Image rejected and removed.");
      fetchPendingPosts();
    } catch (err) {
      alert("Error: " + err.message);
    }
  }

  // Scrolling Controls
  function scrollLeftCards() {
    const container = document.getElementById("pendingPostsContainer");
    container.scrollBy({ left: -300, behavior: "smooth" });
  }

  function scrollRightCards() {
    const container = document.getElementById("pendingPostsContainer");
    container.scrollBy({ left: 300, behavior: "smooth" });
  }






















// Smooth Scroll Functions
function scrollLeftCards() {
const wrapper = document.getElementById("cardsWrapper");
wrapper.scrollBy({
  left: -wrapper.clientWidth,  // Scroll by the full width of the container
  behavior: "smooth"
});
}

function scrollRightCards() {
const wrapper = document.getElementById("cardsWrapper");
wrapper.scrollBy({
  left: wrapper.clientWidth,  // Scroll by the full width of the container
  behavior: "smooth"
});
}

// Smooth Fade-in Animation for Cards
window.addEventListener("load", function() {
const wrapper = document.getElementById("cardsWrapper");
setTimeout(() => {
  wrapper.classList.add("loaded");
}, 200); // Delay to make it smooth
});


//   ////////////////////////////////////////////////
const users = [
{ fullName: "Alex Xavier", email: "alex@example.com", age: 28, gender: "Male", points: 1500 },
{ fullName: "Sarah Johnson", email: "sarah@example.com", age: 24, gender: "Female", points: 800 },
{ fullName: "George Oliver", email: "george@example.com", age: 30, gender: "Male", points: 1200 },
{ fullName: "Lisa Brown", email: "lisa@example.com", age: 22, gender: "Female", points: 950 },
{ fullName: "John Doe", email: "john@example.com", age: 32, gender: "Male", points: 500 },
{ fullName: "Emily Davis", email: "emily@example.com", age: 27, gender: "Female", points: 1300 },
{ fullName: "Mark White", email: "mark@example.com", age: 29, gender: "Male", points: 720 },
{ fullName: "Sophia Green", email: "sophia@example.com", age: 26, gender: "Female", points: 1100 },
{ fullName: "Daniel Black", email: "daniel@example.com", age: 25, gender: "Male", points: 680 },
{ fullName: "Nina Scott", email: "nina@example.com", age: 23, gender: "Female", points: 900 }
];

let currentPage = 1;
const rowsPerPage = 5;

// Function to Display Users
// Function to Display Users
function displayUsers(page) {
const tbody = document.getElementById("customerTableBody");
tbody.innerHTML = "";

const start = (page - 1) * rowsPerPage;
const end = start + rowsPerPage;
const paginatedUsers = users.slice(start, end);

paginatedUsers.forEach(user => {
const row = `
  <tr>
    <td><input type="checkbox" class="user-checkbox"></td>
    <td>${user.fullName}</td>
    <td>${user.email}</td>
    <td>${user.age}</td>
    <td>${user.gender}</td>
    <td>${user.points}</td>
    <td>
      <button class="edit-btn"><i class="fas fa-pencil-alt"></i></button>
      <button class="delete-btn"><i class="fas fa-trash"></i></button>
    </td>
  </tr>
`;
tbody.insertAdjacentHTML("beforeend", row);
});

document.getElementById("data-info").innerText = `Showing ${start + 1}-${Math.min(end, users.length)} out of ${users.length} data`;
setupPagination();
}

// Pagination Control
function setupPagination() {
const totalPages = Math.ceil(users.length / rowsPerPage);
const pageNumbers = document.getElementById("pageNumbers");
pageNumbers.innerHTML = "";

for (let i = 1; i <= totalPages; i++) {
  const button = document.createElement("button");
  button.classList.add("page-btn");
  button.innerText = i;
  button.onclick = () => changePage(i);
  if (i === currentPage) button.classList.add("active");
  pageNumbers.appendChild(button);
}
}

function changePage(page) {
currentPage = page;
displayUsers(currentPage);
}

function nextPage() {
const totalPages = Math.ceil(users.length / rowsPerPage);
if (currentPage < totalPages) {
  currentPage++;
  displayUsers(currentPage);
}
}

function previousPage() {
if (currentPage > 1) {
  currentPage--;
  displayUsers(currentPage);
}
}

// Initial Load
displayUsers(currentPage);

// Search Function
function filterCustomers() {
const searchValue = document.getElementById("searchInput").value.toLowerCase();
const filteredUsers = users.filter(user =>
  user.fullName.toLowerCase().includes(searchValue)
);

displayFilteredUsers(filteredUsers);
}

function displayFilteredUsers(filteredUsers) {
const tbody = document.getElementById("customerTableBody");
tbody.innerHTML = "";

filteredUsers.slice(0, rowsPerPage).forEach(user => {
  const row = `
    <tr>
      <td><input type="checkbox"></td>
      <td>${user.fullName}</td>
      <td>${user.email}</td>
      <td>${user.age}</td>
      <td>${user.gender}</td>
      <td>${user.points}</td>
      <td>
        <button class="edit-btn"><i class="fas fa-pencil-alt"></i></button>
        <button class="delete-btn"><i class="fas fa-trash"></i></button>
      </td>
    </tr>
  `;
  tbody.insertAdjacentHTML("beforeend", row);
});

document.getElementById("data-info").innerText = `Showing ${filteredUsers.length > 0 ? 1 : 0}-${Math.min(rowsPerPage, filteredUsers.length)} out of ${filteredUsers.length} data`;
}
function toggleAllCheckboxes(source) {
const checkboxes = document.querySelectorAll(".user-checkbox");
checkboxes.forEach((checkbox) => {
checkbox.checked = source.checked;
});
}