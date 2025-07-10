$(document).ready(function () {
  let selectedTag = null;
  let currentSearch = null;
  let currentSort = "newest";

  const scrollToResults = () => {
    setTimeout(() => {
      $("html, body").animate({
        scrollTop: $(".blog_1l").offset().top - 75
      }, 400);
    }, 10);
  };

  // Show loading state in results area
  const showLoading = (message = "Loading...") => {
    $(".blog_1l").html(`
      <div class="text-center my-4">
        <div class="spinner-border text-success" role="status" style="width: 4rem; height: 4rem;"></div>
        <p class="mt-2">${message}</p>
      </div>
    `);
  };

  // Update UI state based on current filters
  const updateUIState = () => {
    // Update tag buttons
    $(".tag-filter").removeClass("active btn-success").addClass("btn-outline-success");
    if (selectedTag) {
      $(`.tag-filter[data-tag='${selectedTag}']`).addClass("active btn-success").removeClass("btn-outline-success");
      $("#clear-filter").removeClass("d-none");
    } else {
      $("#clear-filter").addClass("d-none");
    }

    // Update search clear button
    if (currentSearch && currentSearch.trim()) {
      $("#clear-search-btn").removeClass("hidden").addClass("show");
      $("#top-search-input").val(currentSearch); // Make sure input field shows current search
    } else {
      $("#clear-search-btn").removeClass("show").addClass("hidden");
      $("#top-search-input").val("");
    }

    // Update sort dropdown
    $('#sortSelect').val(currentSort);
  };

  // Load content based on current filters
  const loadContent = (page = 1) => {
    let url = "/projects";
    let data = { page };
    let loadingMessage = "Loading projects...";

    if (selectedTag) {
      url = "/projects/filter";
      data.tag = selectedTag;
      loadingMessage = "Loading filtered results...";
    } else if (currentSearch) {
      url = "/projects/search";
      data.query = currentSearch;
      loadingMessage = "Searching...";
    }

    if (currentSort && currentSort !== "newest") {
      data.sort = currentSort;
    }

    showLoading(loadingMessage);

    $.ajax({
      url: url,
      type: "GET",
      data: data,
      headers: { "X-Requested-With": "XMLHttpRequest" },
      success: function (html) {
        $(".blog_1l").html($(html).find(".blog_1l").html());
        // Update UI state after content is loaded
        updateUIState();
      },
      error: function () {
        $(".blog_1l").html("<div class='alert alert-danger mt-4'>Something went wrong.</div>");
      }
    });
  };

  // SEARCH
  $("#top-search-btn").click(function () {
    const query = $("#top-search-input").val().trim();
    if (!query) return;
    
    currentSearch = query;
    selectedTag = null;
    currentSort = "newest";
    
    scrollToResults();
    loadContent();
  });

  $("#top-search-input").on("input", function () {
    if ($(this).val().trim()) {
      $("#clear-search-btn").removeClass("hidden").addClass("show");
    } else {
      $("#clear-search-btn").removeClass("show").addClass("hidden");
    }
  });

  $("#clear-search-btn").click(function () {
    $("#top-search-input").val("");
    $(this).removeClass("show").addClass("hidden");
    currentSearch = null;
    
    scrollToResults();
    loadContent();
  });

  // TAG FILTER
  $(".tag-filter").click(function (e) {
    e.preventDefault();
    const tag = $(this).data("tag");
    
    selectedTag = tag;
    currentSearch = null;
    $("#top-search-input").val("");
    currentSort = "newest";
    
    scrollToResults();
    loadContent();
  });

  // PAGINATION
  $(document).on("click", ".page-link", function (e) {
    e.preventDefault();
    const page = $(this).data("page");
    
    scrollToResults();
    loadContent(page);
  });

  // SORTING
  $(document).on('change', '#sortSelect', function () {
    currentSort = $(this).val();
    
    // Maintain current search and tag filters when sorting
    // (not resetting them as in the original code)
    
    scrollToResults();
    loadContent();
  });
  
  // CLEAR FILTER
  $("#clear-filter").click(function () {
    selectedTag = null;
    currentSort = "newest";
    
    scrollToResults();
    loadContent();
  });

  // CLEAR ALL FILTERS
  $("#clear-all").click(function() {
    selectedTag = null;
    currentSearch = null;
    currentSort = "newest";
    $("#top-search-input").val("");
    $("#clear-search-btn").removeClass("show").addClass("hidden");
    
    scrollToResults();
    loadContent();
  });
});

// DROPDOWN ANIMATION
document.addEventListener('DOMContentLoaded', function () {
  const sortDropdown = document.getElementById('sortSelect');
  if (sortDropdown) {
    sortDropdown.addEventListener('change', () => {
      sortDropdown.classList.add('animate');
      setTimeout(() => sortDropdown.classList.remove('animate'), 200);
    });
  }
});

// CAROUSEL + STICKY NAVBAR + FAVORITE/LIKE/DISLIKE
document.addEventListener('DOMContentLoaded', function () {
  // CAROUSEL
  const track = document.getElementById('carouselTrack');
  if (track) {
    const cards = document.querySelectorAll('.carousel-card');
    if (cards.length > 0) {
      const cardWidth = cards[0].offsetWidth + 20;
      const trackStyle = track.style;

      trackStyle.willChange = 'transform';
      trackStyle.backfaceVisibility = 'hidden';

      let currentPosition = 0;
      let isHovering = false;
      let lastTime = 0;

      function animateCarousel(time) {
        if (!lastTime) lastTime = time;
        const deltaTime = time - lastTime;
        lastTime = time;

        if (!isHovering) {
          const movement = 0.5 * (deltaTime / 16);
          currentPosition -= movement;
          if (Math.abs(currentPosition) >= cardWidth) {
            currentPosition += cardWidth;
            const fragment = document.createDocumentFragment();
            fragment.appendChild(track.firstElementChild);
            track.appendChild(fragment);
          }
          trackStyle.transform = `translate3d(${currentPosition}px, 0, 0)`;
        }

        requestAnimationFrame(animateCarousel);
      }

      requestAnimationFrame(animateCarousel);

      const container = document.querySelector('.carousel-container');
      if (container) {
        container.addEventListener('mouseenter', () => isHovering = true);
        container.addEventListener('mouseleave', () => {
          isHovering = false;
          lastTime = performance.now();
        });
      }
    }
  }

  // LIKE/DISLIKE/FAVORITE
  document.querySelectorAll('.blog_1l').forEach(container => {
    container.addEventListener('click', function (e) {
      const target = e.target;

      // LIKE
      if (target.classList.contains('fa-thumbs-up')) {
        const postId = target.dataset.postId;
        const countEl = target.nextElementSibling;
        const down = target.closest('.thumb-actions').querySelector('.fa-thumbs-down');
        const downCount = down?.nextElementSibling;
        if (target.classList.contains('active')) return;
        target.classList.add('active', 'fas');
        target.classList.remove('far');
        countEl.textContent = +countEl.textContent + 1;
        if (down.classList.contains('active')) {
          down.classList.remove('active', 'fas');
          down.classList.add('far');
          if (downCount) downCount.textContent = +downCount.textContent - 1;
        }
        fetch(`/projects/toggle-like-dislike/${postId}`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-Requested-With': 'XMLHttpRequest'
          },
          body: JSON.stringify({ action: 'like' })
        }).then(res => res.json()).then(data => {
          countEl.textContent = data.likesCount;
          if (downCount) downCount.textContent = data.dislikesCount;
        });
      }

      // DISLIKE
      if (target.classList.contains('fa-thumbs-down')) {
        const postId = target.dataset.postId;
        const countEl = target.nextElementSibling;
        const up = target.closest('.thumb-actions').querySelector('.fa-thumbs-up');
        const upCount = up?.nextElementSibling;
        if (target.classList.contains('active')) return;
        target.classList.add('active', 'fas');
        target.classList.remove('far');
        countEl.textContent = +countEl.textContent + 1;
        if (up.classList.contains('active')) {
          up.classList.remove('active', 'fas');
          up.classList.add('far');
          if (upCount) upCount.textContent = +upCount.textContent - 1;
        }
        fetch(`/projects/toggle-like-dislike/${postId}`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-Requested-With': 'XMLHttpRequest'
          },
          body: JSON.stringify({ action: 'dislike' })
        }).then(res => res.json()).then(data => {
          countEl.textContent = data.dislikesCount;
          if (upCount) upCount.textContent = data.likesCount;
        });
      }

      // FAVORITE
      if (target.classList.contains('favorite-icon')) {
        const postId = target.dataset.postId;
        fetch(`/projects/toggle-favorite/${postId}`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-Requested-With': 'XMLHttpRequest'
          }
        }).then(res => res.json()).then(data => {
          target.classList.toggle('fas', data.action === 'added');
          target.classList.toggle('far', data.action === 'removed');
          target.classList.toggle('active', data.action === 'added');
          let msg = document.getElementById('global-notification');
          if (!msg) {
            msg = document.createElement('div');
            msg.id = 'global-notification';
            msg.className = 'notification';
            document.body.appendChild(msg);
          }
          msg.textContent = data.action === 'added'
            ? "This item is saved in your favorites"
            : "This item was removed from your favorites";
          msg.className = `notification ${data.action === 'added' ? 'success' : 'removed'} show`;
          setTimeout(() => msg.classList.remove('show'), 2000);
        });
      }
    });
  });

  // STICKY NAVBAR
  const navbar_sticky = document.getElementById("navbar_sticky");
  if (navbar_sticky) {
    const sticky = navbar_sticky.offsetTop;
    const navbar_height = document.querySelector('.navbar')?.offsetHeight || 0;

    window.onscroll = function () {
      if (window.pageYOffset >= sticky + navbar_height) {
        navbar_sticky.classList.add("sticky");
        document.body.style.paddingTop = navbar_height + 'px';
      } else {
        navbar_sticky.classList.remove("sticky");
        document.body.style.paddingTop = '0';
      }
    };
  }
});