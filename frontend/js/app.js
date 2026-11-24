"use strict";

const prefersReducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)");

const state = {
  user: null,
  categories: [],
  publishers: [],
  sliders: [],
  availableImages: [],
  books: [],
  viewMode: "grid",
  page: 1,
  pageSize: 12,
  total: 0,
  isLoading: false,
  loadError: null,
  statsAnimated: false,
  filters: {
    q: "",
    ma_cd: "",
    ma_nxb: "",
  },
  carousel: {
    index: 0,
    paused: prefersReducedMotion.matches,
    hoverPaused: false,
    focusPaused: false,
    timerId: null,
  },
};

const el = {
  siteNav: document.getElementById("site-nav"),
  healthPill: document.getElementById("health-pill"),
  healthText: document.getElementById("health-text"),
  guestActions: document.getElementById("guest-actions"),
  userActions: document.getElementById("user-actions"),
  userName: document.getElementById("user-name"),
  userRole: document.getElementById("user-role"),
  authHint: document.getElementById("auth-hint"),

  heroChartBars: document.getElementById("hero-chart-bars"),
  heroChartTotal: document.getElementById("hero-chart-total"),
  heroRecentBooks: document.getElementById("hero-recent-books"),
  heroAvgPrice: document.getElementById("hero-avg-price"),
  heroImageCount: document.getElementById("hero-image-count"),
  btnHeroAdd: document.getElementById("btn-hero-add"),
  btnCtaRegister: document.getElementById("btn-cta-register"),

  publisherMarquee: document.getElementById("publisher-marquee"),
  featureCoverShowcase: document.getElementById("feature-cover-showcase"),

  heroCarousel: document.getElementById("hero-carousel"),
  carouselTrack: document.getElementById("carousel-track"),
  carouselCounter: document.getElementById("carousel-counter"),
  carouselCaption: document.getElementById("carousel-caption"),
  carouselDots: document.getElementById("carousel-dots"),
  btnSlidePrev: document.getElementById("btn-slide-prev"),
  btnSlideNext: document.getElementById("btn-slide-next"),
  btnSlideToggle: document.getElementById("btn-slide-toggle"),
  slideToggleLabel: document.getElementById("slide-toggle-label"),
  iconPause: document.getElementById("icon-pause"),
  iconPlay: document.getElementById("icon-play"),

  statBooks: document.getElementById("stat-total-books"),
  statCategories: document.getElementById("stat-total-categories"),
  statPublishers: document.getElementById("stat-total-publishers"),

  btnViewGrid: document.getElementById("btn-view-grid"),
  btnViewTable: document.getElementById("btn-view-table"),
  filterForm: document.getElementById("filter-form"),
  searchInput: document.getElementById("search-input"),
  filterCategory: document.getElementById("filter-category"),
  filterPublisher: document.getElementById("filter-publisher"),

  booksGridRegion: document.getElementById("books-grid-region"),
  booksGrid: document.getElementById("books-grid"),
  booksTableRegion: document.getElementById("books-table-region"),
  booksTbody: document.getElementById("books-tbody"),
  booksStateBox: document.getElementById("books-state-box"),
  stateTitle: document.getElementById("state-title"),
  stateDesc: document.getElementById("state-desc"),
  btnStateAction: document.getElementById("btn-state-action"),

  paginationInfo: document.getElementById("pagination-info"),
  pageIndicator: document.getElementById("page-indicator"),
  btnPrevPage: document.getElementById("btn-prev-page"),
  btnNextPage: document.getElementById("btn-next-page"),

  btnAddBook: document.getElementById("btn-add-book"),
  btnOpenLogin: document.getElementById("btn-open-login"),
  btnOpenRegister: document.getElementById("btn-open-register"),
  btnLogout: document.getElementById("btn-logout"),
  btnResetFilter: document.getElementById("btn-reset-filter"),

  loginDialog: document.getElementById("login-dialog"),
  loginForm: document.getElementById("login-form"),
  loginError: document.getElementById("login-error"),

  registerDialog: document.getElementById("register-dialog"),
  registerForm: document.getElementById("register-form"),
  registerError: document.getElementById("register-error"),

  bookDialog: document.getElementById("book-dialog"),
  bookDialogTitle: document.getElementById("book-dialog-title"),
  bookForm: document.getElementById("book-form"),
  bookError: document.getElementById("book-error"),
  bookId: document.getElementById("book-id"),
  bookTitle: document.getElementById("book-title"),
  bookCategory: document.getElementById("book-category"),
  bookPublisher: document.getElementById("book-publisher"),
  bookPrice: document.getElementById("book-price"),
  bookQty: document.getElementById("book-qty"),
  bookCoverSelect: document.getElementById("book-cover-select"),
  bookCover: document.getElementById("book-cover"),
  bookCoverPreviewImg: document.getElementById("book-cover-preview-img"),
  bookCoverPreviewEmpty: document.getElementById("book-cover-preview-empty"),
  bookCoverPreviewName: document.getElementById("book-cover-preview-name"),
  coverPickerGrid: document.getElementById("cover-picker-grid"),
  pickerCount: document.getElementById("picker-count"),
  bookDesc: document.getElementById("book-desc"),

  detailDialog: document.getElementById("detail-dialog"),
  detailTitle: document.getElementById("detail-title"),
  detailBody: document.getElementById("detail-body"),

  toastRegion: document.getElementById("toast-region"),
};

/* ==========================================================================
   Helpers
   ========================================================================== */
function formatCurrency(amount) {
  return new Intl.NumberFormat("vi-VN").format(Math.round(Number(amount || 0))) + " đ";
}

function resolveBookCoverUrl(bookOrFilename) {
  if (!bookOrFilename) return null;
  if (typeof bookOrFilename === "object") {
    if (bookOrFilename.AnhBiaUrl) return bookOrFilename.AnhBiaUrl;
    return resolveBookCoverUrl(bookOrFilename.AnhBia);
  }
  const clean = String(bookOrFilename).trim().replace(/^\/?Images\//i, "");
  if (!clean || clean.includes("/") || clean.includes("\\") || clean.includes("..")) {
    return null;
  }
  return `/Images/${encodeURIComponent(clean)}`;
}

function createBookFallbackEl(label = "Chưa có bìa") {
  const wrap = document.createElement("div");
  wrap.className = "cover-fallback";

  const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
  svg.setAttribute("viewBox", "0 0 24 24");
  svg.setAttribute("width", "26");
  svg.setAttribute("height", "26");
  svg.setAttribute("fill", "none");
  svg.setAttribute("stroke", "currentColor");
  svg.setAttribute("stroke-width", "1.6");
  svg.setAttribute("aria-hidden", "true");

  const path1 = document.createElementNS("http://www.w3.org/2000/svg", "path");
  path1.setAttribute("d", "M4 19.5A2.5 2.5 0 0 1 6.5 17H20");
  const path2 = document.createElementNS("http://www.w3.org/2000/svg", "path");
  path2.setAttribute("d", "M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z");
  svg.append(path1, path2);

  const text = document.createElement("span");
  text.textContent = label;
  wrap.append(svg, text);
  return wrap;
}

function createSafeCoverImg(url, altText, className, fallbackLabel) {
  if (!url) return createBookFallbackEl(fallbackLabel);
  const img = document.createElement("img");
  img.src = url;
  img.alt = altText;
  img.className = className;
  img.loading = "lazy";
  img.addEventListener("error", () => {
    img.replaceWith(createBookFallbackEl(fallbackLabel));
  });
  return img;
}

function showToast(message, type = "info") {
  const toast = document.createElement("div");
  toast.className = `toast ${type === "success" ? "toast-success" : type === "error" ? "toast-error" : ""}`;
  toast.textContent = message;
  el.toastRegion.appendChild(toast);
  setTimeout(() => toast.remove(), 3600);
}

function setFormError(targetEl, message) {
  if (!message) {
    targetEl.textContent = "";
    targetEl.classList.add("hidden");
    return;
  }
  targetEl.textContent = message;
  targetEl.classList.remove("hidden");
}

function animateCounter(node, target) {
  const numericTarget = Number(target) || 0;
  node.dataset.target = String(numericTarget);
  if (prefersReducedMotion.matches || numericTarget <= 0) {
    node.textContent = String(numericTarget);
    return;
  }
  const duration = 1100;
  const start = performance.now();
  function tick(now) {
    const t = Math.min(1, (now - start) / duration);
    const eased = 1 - Math.pow(1 - t, 3);
    node.textContent = String(Math.round(numericTarget * eased));
    if (t < 1) requestAnimationFrame(tick);
  }
  requestAnimationFrame(tick);
}

async function apiRequest(path, options = {}) {
  const config = {
    credentials: "same-origin",
    headers: {
      "Content-Type": "application/json",
      ...(options.headers || {}),
    },
    ...options,
  };
  const response = await fetch(path, config);
  let data = null;
  try {
    data = await response.json();
  } catch {
    data = null;
  }
  if (!response.ok) {
    const detail =
      data && typeof data.detail === "string"
        ? data.detail
        : data && Array.isArray(data.detail) && data.detail[0]?.msg
          ? data.detail[0].msg
          : `Yêu cầu thất bại (HTTP ${response.status})`;
    const err = new Error(detail);
    err.status = response.status;
    throw err;
  }
  return data;
}

/* ==========================================================================
   Hero Live Floating Cards, Publisher Marquee & Feature Mosaic
   ========================================================================== */
function renderHeroCards(allBooks) {
  // 1. Warm Yellow Bar Chart (top 5 categories by book count)
  const counts = new Map();
  let sumPrice = 0;
  for (const b of allBooks) {
    const cat = b.TenChuDe || "Khác";
    counts.set(cat, (counts.get(cat) || 0) + 1);
    sumPrice += Number(b.GiaBan || 0);
  }

  const topCats = Array.from(counts.entries())
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5);
  const maxVal = Math.max(1, ...topCats.map((item) => item[1]));

  el.heroChartBars.replaceChildren();
  for (const [label, count] of topCats) {
    const col = document.createElement("div");
    col.className = "bar-col";

    const valEl = document.createElement("span");
    valEl.className = "bar-val";
    valEl.textContent = String(count);

    const fill = document.createElement("div");
    const bucket = Math.min(80, Math.max(20, Math.round((count / maxVal) * 8) * 10));
    fill.className = `bar-fill bar-h-${bucket}`;

    const lbl = document.createElement("span");
    lbl.className = "bar-lbl";
    lbl.title = label;
    lbl.textContent = label.split(" ").slice(0, 2).join(" ");

    col.append(valEl, fill, lbl);
    el.heroChartBars.appendChild(col);
  }
  el.heroChartTotal.textContent = `${allBooks.length} đầu sách`;

  // 2. Center Card: 3 Featured Real Books with Covers from Images/
  el.heroRecentBooks.replaceChildren();
  for (const book of allBooks.slice(0, 3)) {
    const btn = document.createElement("button");
    btn.type = "button";
    btn.className = "hero-book-row";
    btn.addEventListener("click", () => openBookDetail(book.MaSach));

    const thumb = createSafeCoverImg(
      resolveBookCoverUrl(book),
      `Bìa ${book.TenSach}`,
      "hero-book-thumb",
      "Sách"
    );

    const info = document.createElement("span");
    info.className = "hero-book-info";
    const name = document.createElement("span");
    name.className = "hero-book-name";
    name.textContent = book.TenSach;
    const cat = document.createElement("span");
    cat.className = "hero-book-cat";
    cat.textContent = book.TenChuDe || "Chưa phân loại";
    info.append(name, cat);

    const price = document.createElement("span");
    price.className = "hero-book-price";
    price.textContent = formatCurrency(book.GiaBan);

    btn.append(thumb, info, price);
    el.heroRecentBooks.appendChild(btn);
  }

  // 3. Right Card: Avg Price + Image Count
  const avgPrice = allBooks.length ? sumPrice / allBooks.length : 0;
  el.heroAvgPrice.textContent = formatCurrency(avgPrice);
}

function renderPublisherMarquee() {
  el.publisherMarquee.replaceChildren();
  const names = state.publishers.length
    ? state.publishers.map((p) => p.TenNXB)
    : ["Nhà xuất bản Trẻ", "NXB Thống kê", "Kim đồng", "Đại học quốc gia", "Khoa Học & Kỹ Thuật"];

  // Nhân đôi danh sách để marquee cuộn vô hạn mượt mà
  const loopItems = [...names, ...names];
  for (const name of loopItems) {
    const item = document.createElement("span");
    item.className = "marquee-item";
    item.textContent = name;
    el.publisherMarquee.appendChild(item);
  }
}

function renderFeatureCoverShowcase() {
  el.featureCoverShowcase.replaceChildren();
  for (const asset of state.availableImages.slice(0, 6)) {
    const tile = document.createElement("div");
    tile.className = "mosaic-tile";

    const img = document.createElement("img");
    img.src = asset.url;
    img.alt = `Ảnh bìa ${asset.filename}`;
    img.loading = "lazy";

    const name = document.createElement("span");
    name.textContent = asset.filename;

    tile.append(img, name);
    el.featureCoverShowcase.appendChild(tile);
  }
}

/* ==========================================================================
   Accessible Carousel (Images/Slider/*)
   ========================================================================== */
function updateCarouselUI() {
  const total = state.sliders.length;
  if (!total) return;

  const slides = el.carouselTrack.querySelectorAll(".carousel-slide");
  const dots = el.carouselDots.querySelectorAll(".carousel-dot");

  slides.forEach((slide, idx) => {
    const isActive = idx === state.carousel.index;
    slide.classList.toggle("active", isActive);
    slide.setAttribute("aria-hidden", isActive ? "false" : "true");
  });

  dots.forEach((dot, idx) => {
    if (idx === state.carousel.index) {
      dot.setAttribute("aria-current", "true");
    } else {
      dot.removeAttribute("aria-current");
    }
  });

  const current = state.sliders[state.carousel.index];
  el.carouselCounter.textContent = `${state.carousel.index + 1} / ${total}`;
  el.carouselCaption.textContent = current.TenSlider || `Banner ${state.carousel.index + 1}`;
}

function syncCarouselToggleUI() {
  const paused = state.carousel.paused;
  el.btnSlideToggle.setAttribute("aria-pressed", paused ? "true" : "false");
  el.btnSlideToggle.setAttribute(
    "aria-label",
    paused ? "Tiếp tục trình chiếu banner" : "Tạm dừng trình chiếu banner"
  );
  el.slideToggleLabel.textContent = paused ? "Phát tiếp" : "Tạm dừng";
  el.iconPause.classList.toggle("hidden", paused);
  el.iconPlay.classList.toggle("hidden", !paused);
}

function stopCarouselTimer() {
  if (state.carousel.timerId !== null) {
    window.clearInterval(state.carousel.timerId);
    state.carousel.timerId = null;
  }
}

function startCarouselTimer() {
  stopCarouselTimer();
  if (
    state.sliders.length <= 1 ||
    state.carousel.paused ||
    state.carousel.hoverPaused ||
    state.carousel.focusPaused ||
    prefersReducedMotion.matches
  ) {
    return;
  }
  state.carousel.timerId = window.setInterval(() => {
    state.carousel.index = (state.carousel.index + 1) % state.sliders.length;
    updateCarouselUI();
  }, 5000);
}

function goToSlide(nextIndex) {
  const total = state.sliders.length;
  if (!total) return;
  state.carousel.index = ((nextIndex % total) + total) % total;
  updateCarouselUI();
  startCarouselTimer();
}

function renderCarousel() {
  if (!state.sliders.length) {
    el.heroCarousel.classList.add("hidden");
    return;
  }
  el.heroCarousel.classList.remove("hidden");
  el.carouselTrack.replaceChildren();
  el.carouselDots.replaceChildren();

  state.sliders.forEach((slide, idx) => {
    const slideEl = document.createElement("div");
    slideEl.className = "carousel-slide";
    slideEl.setAttribute("role", "group");
    slideEl.setAttribute("aria-roledescription", "slide");
    slideEl.setAttribute("aria-label", `${idx + 1} trên ${state.sliders.length}: ${slide.TenSlider}`);

    const img = document.createElement("img");
    img.src = slide.HinhAnhUrl || `/Images/Slider/${encodeURIComponent(slide.HinhAnh)}`;
    img.alt = slide.TenSlider || `Banner sách ${idx + 1}`;
    img.loading = idx === 0 ? "eager" : "lazy";
    slideEl.appendChild(img);
    el.carouselTrack.appendChild(slideEl);

    const dot = document.createElement("button");
    dot.type = "button";
    dot.className = "carousel-dot";
    dot.setAttribute("aria-label", `Chuyển tới banner ${idx + 1}`);
    dot.addEventListener("click", () => goToSlide(idx));
    el.carouselDots.appendChild(dot);
  });

  state.carousel.index = 0;
  updateCarouselUI();
  syncCarouselToggleUI();
  startCarouselTimer();
}

/* ==========================================================================
   Auth & Selects
   ========================================================================== */
function renderAuthUI() {
  if (state.user) {
    el.guestActions.classList.add("hidden");
    el.userActions.classList.remove("hidden");
    el.authHint.classList.add("hidden");
    el.userName.textContent = `${state.user.full_name} (@${state.user.username})`;
    el.userRole.textContent = state.user.role === "admin" ? "Quản trị" : "Thành viên";
  } else {
    el.guestActions.classList.remove("hidden");
    el.userActions.classList.add("hidden");
    el.authHint.classList.remove("hidden");
    el.userName.textContent = "";
    el.userRole.textContent = "";
  }
}

function populateSelect(selectEl, items, valueKey, labelKey, placeholder) {
  selectEl.replaceChildren();
  if (placeholder !== null) {
    const opt = document.createElement("option");
    opt.value = "";
    opt.textContent = placeholder;
    selectEl.appendChild(opt);
  }
  for (const item of items) {
    const opt = document.createElement("option");
    opt.value = String(item[valueKey]);
    opt.textContent = item[labelKey];
    selectEl.appendChild(opt);
  }
}

/* ==========================================================================
   Visual Cover Picker (Images/)
   ========================================================================== */
function updateCoverPreview(rawFilename) {
  const clean = String(rawFilename || "").trim().replace(/^\/?Images\//i, "");
  const url = resolveBookCoverUrl(clean);

  el.bookCoverPreviewName.textContent = clean || "Không có tệp";

  const hasOption = Array.from(el.bookCoverSelect.options).some((o) => o.value === clean);
  el.bookCoverSelect.value = hasOption ? clean : "";

  el.coverPickerGrid.querySelectorAll(".picker-thumb-btn").forEach((btn) => {
    btn.setAttribute("aria-selected", btn.dataset.filename === clean ? "true" : "false");
  });

  if (!url) {
    el.bookCoverPreviewImg.classList.add("hidden");
    el.bookCoverPreviewImg.removeAttribute("src");
    el.bookCoverPreviewEmpty.classList.remove("hidden");
    return;
  }

  el.bookCoverPreviewEmpty.classList.add("hidden");
  el.bookCoverPreviewImg.classList.remove("hidden");
  el.bookCoverPreviewImg.src = url;
}

function renderCoverPicker() {
  populateSelect(
    el.bookCoverSelect,
    state.availableImages,
    "filename",
    "filename",
    "-- Không dùng ảnh bìa --"
  );
  el.pickerCount.textContent = `${state.availableImages.length} ảnh sẵn có`;
  el.heroImageCount.textContent = `${state.availableImages.length} tệp`;
  el.coverPickerGrid.replaceChildren();

  for (const asset of state.availableImages) {
    const btn = document.createElement("button");
    btn.type = "button";
    btn.className = "picker-thumb-btn";
    btn.dataset.filename = asset.filename;
    btn.setAttribute("role", "option");
    btn.setAttribute("aria-selected", "false");
    btn.title = asset.filename;

    const img = document.createElement("img");
    img.src = asset.url;
    img.alt = `Ảnh bìa ${asset.filename}`;
    img.className = "picker-thumb-img";
    img.loading = "lazy";

    const lbl = document.createElement("span");
    lbl.className = "picker-thumb-label";
    lbl.textContent = asset.filename;

    btn.append(img, lbl);
    btn.addEventListener("click", () => {
      el.bookCover.value = asset.filename;
      updateCoverPreview(asset.filename);
    });
    el.coverPickerGrid.appendChild(btn);
  }
}

/* ==========================================================================
   Books Catalog Rendering (Grid & Table)
   ========================================================================== */
function renderLoadingSkeleton() {
  el.booksStateBox.classList.add("hidden");
  el.booksTableRegion.classList.add("hidden");
  el.booksGridRegion.classList.remove("hidden");
  el.booksGridRegion.setAttribute("aria-busy", "true");
  el.booksGrid.replaceChildren();

  for (let i = 0; i < 8; i += 1) {
    const card = document.createElement("div");
    card.className = "skeleton-card";
    const cover = document.createElement("div");
    cover.className = "skeleton-box skeleton-cover";
    const body = document.createElement("div");
    body.className = "skeleton-body";
    const l1 = document.createElement("div");
    l1.className = "skeleton-box skeleton-line";
    const l2 = document.createElement("div");
    l2.className = "skeleton-box skeleton-line skeleton-line-short";
    body.append(l1, l2);
    card.append(cover, body);
    el.booksGrid.appendChild(card);
  }
}

function renderBooksGrid() {
  el.booksGrid.replaceChildren();

  for (const book of state.books) {
    const card = document.createElement("article");
    card.className = "book-card";

    const coverBtn = document.createElement("button");
    coverBtn.type = "button";
    coverBtn.className = "book-cover-btn";
    coverBtn.setAttribute("aria-label", `Xem chi tiết sách ${book.TenSach}`);
    coverBtn.addEventListener("click", () => openBookDetail(book.MaSach));

    const coverFrame = document.createElement("div");
    coverFrame.className = "book-cover-frame";
    coverFrame.appendChild(
      createSafeCoverImg(
        resolveBookCoverUrl(book),
        `Bìa sách ${book.TenSach}`,
        "book-cover-img",
        "Chưa có bìa"
      )
    );
    coverBtn.appendChild(coverFrame);

    const body = document.createElement("div");
    body.className = "book-card-body";

    const metaRow = document.createElement("div");
    metaRow.className = "book-meta-row";
    const catTag = document.createElement("span");
    catTag.className = "book-cat-tag";
    catTag.textContent = book.TenChuDe || "Chưa phân loại";
    const idTag = document.createElement("span");
    idTag.className = "book-id-tag";
    idTag.textContent = `#${book.MaSach}`;
    metaRow.append(catTag, idTag);

    const titleH3 = document.createElement("h3");
    titleH3.className = "book-card-title";
    const titleBtn = document.createElement("button");
    titleBtn.type = "button";
    titleBtn.className = "book-title-link";
    titleBtn.textContent = book.TenSach;
    titleBtn.addEventListener("click", () => openBookDetail(book.MaSach));
    titleH3.appendChild(titleBtn);

    const pub = document.createElement("p");
    pub.className = "book-publisher";
    pub.textContent = book.TenNXB ? `NXB: ${book.TenNXB}` : "NXB: Đang cập nhật";

    const priceRow = document.createElement("div");
    priceRow.className = "book-price-row";
    const priceEl = document.createElement("span");
    priceEl.className = "book-price";
    priceEl.textContent = formatCurrency(book.GiaBan);
    const qtyEl = document.createElement("span");
    qtyEl.className = "book-qty";
    qtyEl.textContent = `SL: ${book.SoLuongBan}`;
    priceRow.append(priceEl, qtyEl);

    body.append(metaRow, titleH3, pub, priceRow);

    const actions = document.createElement("div");
    actions.className = "book-card-actions";

    const btnView = document.createElement("button");
    btnView.type = "button";
    btnView.className = "btn btn-outline btn-sm";
    btnView.textContent = "Chi tiết";
    btnView.addEventListener("click", () => openBookDetail(book.MaSach));

    const btnEdit = document.createElement("button");
    btnEdit.type = "button";
    btnEdit.className = "btn btn-outline btn-sm";
    btnEdit.textContent = "Sửa";
    btnEdit.addEventListener("click", () => openBookEditor(book));

    const btnDelete = document.createElement("button");
    btnDelete.type = "button";
    btnDelete.className = "btn btn-danger btn-sm";
    btnDelete.textContent = "Xóa";
    btnDelete.addEventListener("click", () => handleDeleteBook(book));

    actions.append(btnView, btnEdit, btnDelete);
    card.append(coverBtn, body, actions);
    el.booksGrid.appendChild(card);
  }
}

function renderBooksTable() {
  el.booksTbody.replaceChildren();

  for (const book of state.books) {
    const tr = document.createElement("tr");

    const tdId = document.createElement("td");
    tdId.className = "book-id-tag";
    tdId.textContent = `#${book.MaSach}`;

    const tdBook = document.createElement("td");
    const bookBox = document.createElement("div");
    bookBox.className = "table-book-cell";

    const coverUrl = resolveBookCoverUrl(book);
    if (coverUrl) {
      const thumb = document.createElement("img");
      thumb.src = coverUrl;
      thumb.alt = `Bìa ${book.TenSach}`;
      thumb.className = "table-thumb";
      thumb.loading = "lazy";
      thumb.addEventListener("error", () => {
        const placeholder = document.createElement("div");
        placeholder.className = "table-thumb-empty";
        placeholder.textContent = "—";
        thumb.replaceWith(placeholder);
      });
      bookBox.appendChild(thumb);
    } else {
      const placeholder = document.createElement("div");
      placeholder.className = "table-thumb-empty";
      placeholder.textContent = "—";
      bookBox.appendChild(placeholder);
    }

    const titleBtn = document.createElement("button");
    titleBtn.type = "button";
    titleBtn.className = "book-title-link book-name-cell";
    titleBtn.textContent = book.TenSach;
    titleBtn.addEventListener("click", () => openBookDetail(book.MaSach));
    bookBox.appendChild(titleBtn);
    tdBook.appendChild(bookBox);

    const tdCat = document.createElement("td");
    tdCat.textContent = book.TenChuDe || "—";

    const tdPub = document.createElement("td");
    tdPub.textContent = book.TenNXB || "—";

    const tdPrice = document.createElement("td");
    tdPrice.className = "num price-cell";
    tdPrice.textContent = formatCurrency(book.GiaBan);

    const tdQty = document.createElement("td");
    tdQty.className = "num";
    tdQty.textContent = String(book.SoLuongBan);

    const tdActions = document.createElement("td");
    const actionBox = document.createElement("div");
    actionBox.className = "row-actions";

    const btnView = document.createElement("button");
    btnView.type = "button";
    btnView.className = "btn btn-outline btn-sm";
    btnView.textContent = "Xem";
    btnView.addEventListener("click", () => openBookDetail(book.MaSach));

    const btnEdit = document.createElement("button");
    btnEdit.type = "button";
    btnEdit.className = "btn btn-outline btn-sm";
    btnEdit.textContent = "Sửa";
    btnEdit.addEventListener("click", () => openBookEditor(book));

    const btnDelete = document.createElement("button");
    btnDelete.type = "button";
    btnDelete.className = "btn btn-danger btn-sm";
    btnDelete.textContent = "Xóa";
    btnDelete.addEventListener("click", () => handleDeleteBook(book));

    actionBox.append(btnView, btnEdit, btnDelete);
    tdActions.appendChild(actionBox);

    tr.append(tdId, tdBook, tdCat, tdPub, tdPrice, tdQty, tdActions);
    el.booksTbody.appendChild(tr);
  }
}

function renderBooks() {
  el.booksGridRegion.setAttribute("aria-busy", "false");

  const isGrid = state.viewMode === "grid";
  el.btnViewGrid.classList.toggle("active", isGrid);
  el.btnViewGrid.setAttribute("aria-pressed", isGrid ? "true" : "false");
  el.btnViewTable.classList.toggle("active", !isGrid);
  el.btnViewTable.setAttribute("aria-pressed", !isGrid ? "true" : "false");

  if (state.loadError) {
    el.booksGridRegion.classList.add("hidden");
    el.booksTableRegion.classList.add("hidden");
    el.booksStateBox.classList.remove("hidden");
    el.stateTitle.textContent = "Không thể tải danh sách sách";
    el.stateDesc.textContent = state.loadError;
    el.btnStateAction.textContent = "Thử tải lại";
    el.btnStateAction.dataset.action = "retry";
  } else if (!state.books.length) {
    el.booksGridRegion.classList.add("hidden");
    el.booksTableRegion.classList.add("hidden");
    el.booksStateBox.classList.remove("hidden");
    el.stateTitle.textContent = "Không tìm thấy cuốn sách nào phù hợp";
    el.stateDesc.textContent = "Hãy thử từ khóa khác hoặc đặt lại bộ lọc để xem toàn bộ kho sách.";
    el.btnStateAction.textContent = "Đặt lại bộ lọc";
    el.btnStateAction.dataset.action = "reset";
  } else {
    el.booksStateBox.classList.add("hidden");
    if (isGrid) {
      el.booksTableRegion.classList.add("hidden");
      el.booksGridRegion.classList.remove("hidden");
      renderBooksGrid();
    } else {
      el.booksGridRegion.classList.add("hidden");
      el.booksTableRegion.classList.remove("hidden");
      renderBooksTable();
    }
  }

  const totalPages = Math.max(1, Math.ceil(state.total / state.pageSize));
  el.paginationInfo.textContent = `Hiển thị ${state.books.length} / ${state.total} đầu sách`;
  el.pageIndicator.textContent = `Trang ${state.page} / ${totalPages}`;
  el.btnPrevPage.disabled = state.page <= 1;
  el.btnNextPage.disabled = state.page >= totalPages;
}

/* ==========================================================================
   Data Loaders
   ========================================================================== */
async function checkHealth() {
  try {
    await apiRequest("/api/health");
    el.healthText.textContent = "API & DB: Hoạt động";
    el.healthPill.className = "status-pill status-ok";
  } catch {
    el.healthText.textContent = "Mất kết nối API";
    el.healthPill.className = "status-pill status-err";
  }
}

async function restoreSession() {
  try {
    state.user = await apiRequest("/api/auth/me");
  } catch {
    state.user = null;
  }
  renderAuthUI();
}

async function loadCatalogsAndMedia() {
  try {
    const [categories, publishers, sliders, images, summaryBooks] = await Promise.all([
      apiRequest("/api/categories"),
      apiRequest("/api/publishers"),
      apiRequest("/api/sliders").catch(() => []),
      apiRequest("/api/images").catch(() => []),
      apiRequest("/api/books?page=1&page_size=100").catch(() => ({ total: 0, items: [] })),
    ]);

    state.categories = categories;
    state.publishers = publishers;
    state.sliders = sliders;
    state.availableImages = images;

    animateCounter(el.statBooks, summaryBooks.total);
    animateCounter(el.statCategories, categories.length);
    animateCounter(el.statPublishers, publishers.length);

    populateSelect(el.filterCategory, categories, "MaCD", "TenChuDe", "Tất cả chủ đề");
    populateSelect(el.filterPublisher, publishers, "MaNXB", "TenNXB", "Tất cả NXB");
    populateSelect(el.bookCategory, categories, "MaCD", "TenChuDe", null);
    populateSelect(el.bookPublisher, publishers, "MaNXB", "TenNXB", null);

    renderHeroCards(summaryBooks.items || []);
    renderPublisherMarquee();
    renderCoverPicker();
    renderFeatureCoverShowcase();
    renderCarousel();
  } catch (err) {
    showToast(err.message, "error");
  }
}

async function loadBooks() {
  state.isLoading = true;
  state.loadError = null;
  renderLoadingSkeleton();

  const params = new URLSearchParams({
    page: String(state.page),
    page_size: String(state.pageSize),
  });
  if (state.filters.q) params.set("q", state.filters.q);
  if (state.filters.ma_cd) params.set("ma_cd", state.filters.ma_cd);
  if (state.filters.ma_nxb) params.set("ma_nxb", state.filters.ma_nxb);

  try {
    const data = await apiRequest(`/api/books?${params.toString()}`);
    state.books = data.items;
    state.total = data.total;
    if (!state.filters.q && !state.filters.ma_cd && !state.filters.ma_nxb) {
      el.statBooks.textContent = String(data.total);
    }
  } catch (err) {
    state.books = [];
    state.total = 0;
    state.loadError = err.message;
    showToast(err.message, "error");
  } finally {
    state.isLoading = false;
    renderBooks();
  }
}

/* ==========================================================================
   Book Detail & CRUD Modals
   ========================================================================== */
async function openBookDetail(maSach) {
  try {
    const book = await apiRequest(`/api/books/${maSach}`);
    el.detailTitle.textContent = `Chi tiết sách #${book.MaSach}`;
    el.detailBody.replaceChildren();

    const coverCol = document.createElement("div");
    coverCol.className = "detail-cover-col";

    const coverStage = document.createElement("div");
    coverStage.className = "detail-cover-stage";
    coverStage.appendChild(
      createSafeCoverImg(
        resolveBookCoverUrl(book),
        `Ảnh bìa sách ${book.TenSach}`,
        "book-cover-img",
        "Chưa có ảnh bìa"
      )
    );

    const fileNote = document.createElement("p");
    fileNote.className = "preview-filename";
    fileNote.textContent = book.AnhBia ? `Images/${book.AnhBia}` : "Chưa gán ảnh bìa";
    coverCol.append(coverStage, fileNote);

    const infoCol = document.createElement("div");
    infoCol.className = "detail-info-col";

    const heading = document.createElement("h4");
    heading.className = "detail-book-heading";
    heading.textContent = book.TenSach;

    const priceBanner = document.createElement("div");
    priceBanner.className = "detail-price-banner";
    const priceVal = document.createElement("span");
    priceVal.className = "detail-price-val";
    priceVal.textContent = formatCurrency(book.GiaBan);
    const stockPill = document.createElement("span");
    stockPill.className = "detail-stock-pill";
    stockPill.textContent = `Số lượng bán: ${book.SoLuongBan}`;
    priceBanner.append(priceVal, stockPill);

    const metaGrid = document.createElement("div");
    metaGrid.className = "detail-meta";
    const metaRows = [
      ["Chủ đề", book.TenChuDe || "Chưa phân loại"],
      ["Nhà xuất bản", book.TenNXB || "Chưa cập nhật"],
      [
        "Tác giả",
        book.TacGia && book.TacGia.length
          ? book.TacGia.map((a) => (a.VaiTro ? `${a.TenTG} (${a.VaiTro})` : a.TenTG)).join(", ")
          : "Chưa cập nhật",
      ],
      [
        "Cập nhật",
        book.NgayCapNhat ? new Date(book.NgayCapNhat).toLocaleDateString("vi-VN") : "—",
      ],
    ];
    for (const [label, value] of metaRows) {
      const box = document.createElement("div");
      const lbl = document.createElement("span");
      lbl.className = "detail-item-label";
      lbl.textContent = label;
      const val = document.createElement("span");
      val.className = "detail-item-value";
      val.textContent = value;
      box.append(lbl, val);
      metaGrid.appendChild(box);
    }

    const desc = document.createElement("p");
    desc.className = "detail-desc";
    desc.textContent =
      book.MoTa && book.MoTa.trim()
        ? book.MoTa
        : "Chưa có mô tả chi tiết cho cuốn sách này.";

    infoCol.append(heading, priceBanner, metaGrid, desc);
    el.detailBody.append(coverCol, infoCol);
    el.detailDialog.showModal();
  } catch (err) {
    showToast(err.message, "error");
  }
}

function openBookEditor(book = null) {
  if (!state.user) {
    showToast("Vui lòng đăng nhập để thêm hoặc chỉnh sửa sách.", "error");
    el.loginDialog.showModal();
    return;
  }
  setFormError(el.bookError, "");

  if (book) {
    el.bookDialogTitle.textContent = `Cập nhật sách #${book.MaSach}`;
    el.bookId.value = String(book.MaSach);
    el.bookTitle.value = book.TenSach || "";
    el.bookCategory.value = book.MaCD ? String(book.MaCD) : "";
    el.bookPublisher.value = book.MaNXB ? String(book.MaNXB) : "";
    el.bookPrice.value = String(book.GiaBan ?? 0);
    el.bookQty.value = String(book.SoLuongBan ?? 1);
    el.bookCover.value = book.AnhBia || "";
    el.bookDesc.value = book.MoTa || "";
  } else {
    el.bookDialogTitle.textContent = "Thêm sách mới";
    el.bookForm.reset();
    el.bookId.value = "";
    el.bookQty.value = "10";
    el.bookPrice.value = "25000";
    el.bookCover.value = "";
  }

  updateCoverPreview(el.bookCover.value);
  el.bookDialog.showModal();
}

async function handleDeleteBook(book) {
  if (!state.user) {
    showToast("Vui lòng đăng nhập để xóa sách.", "error");
    el.loginDialog.showModal();
    return;
  }
  const confirmed = window.confirm(
    `Bạn có chắc chắn muốn xóa cuốn sách "${book.TenSach}" (#${book.MaSach})?`
  );
  if (!confirmed) return;

  try {
    await apiRequest(`/api/books/${book.MaSach}`, { method: "DELETE" });
    showToast(`Đã xóa sách #${book.MaSach}.`, "success");
    await Promise.all([loadBooks(), refreshHeroSummary()]);
  } catch (err) {
    showToast(err.message, "error");
  }
}

async function refreshHeroSummary() {
  try {
    const summaryBooks = await apiRequest("/api/books?page=1&page_size=100");
    el.statBooks.textContent = String(summaryBooks.total);
    renderHeroCards(summaryBooks.items || []);
  } catch {
    // Không làm gián đoạn thao tác chính
  }
}

/* ==========================================================================
   Scroll Reveal, Navbar Scroll State, Feature Tabs & FAQ Accordion
   ========================================================================== */
function initMicroInteractions() {
  // Sticky navbar shadow on scroll > 40px
  const onScroll = () => {
    el.siteNav.classList.toggle("scrolled", window.scrollY > 40);
  };
  window.addEventListener("scroll", onScroll, { passive: true });
  onScroll();

  // Scroll Reveal via IntersectionObserver
  const reveals = document.querySelectorAll(".reveal");
  if ("IntersectionObserver" in window && !prefersReducedMotion.matches) {
    const io = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add("visible");
            io.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.1 }
    );
    reveals.forEach((node) => io.observe(node));
  } else {
    reveals.forEach((node) => node.classList.add("visible"));
  }

  // Feature Tabs
  const tabBtns = document.querySelectorAll(".tab-btn");
  const tabPanels = document.querySelectorAll(".tab-panel");
  tabBtns.forEach((btn) => {
    btn.addEventListener("click", () => {
      const key = btn.dataset.tab;
      tabBtns.forEach((b) => {
        const active = b === btn;
        b.classList.toggle("active", active);
        b.setAttribute("aria-selected", active ? "true" : "false");
      });
      tabPanels.forEach((panel) => {
        panel.classList.toggle("active", panel.dataset.tabPanel === key);
      });
    });
  });

  // FAQ Accordion
  document.querySelectorAll(".faq-trigger").forEach((trigger) => {
    trigger.addEventListener("click", () => {
      const item = trigger.closest(".faq-item");
      const isOpen = item.classList.toggle("open");
      trigger.setAttribute("aria-expanded", isOpen ? "true" : "false");
    });
  });
}

/* ==========================================================================
   Event Bindings
   ========================================================================== */
function bindDialogBackdropClose(dialogEl) {
  dialogEl.addEventListener("click", (evt) => {
    if (evt.target === dialogEl) dialogEl.close();
  });
}

function bindEvents() {
  document.querySelectorAll("[data-close-dialog]").forEach((btn) => {
    btn.addEventListener("click", () => {
      const target = document.getElementById(btn.getAttribute("data-close-dialog"));
      if (target) target.close();
    });
  });

  [el.loginDialog, el.registerDialog, el.bookDialog, el.detailDialog].forEach(
    bindDialogBackdropClose
  );

  // Carousel controls
  el.btnSlidePrev.addEventListener("click", () => goToSlide(state.carousel.index - 1));
  el.btnSlideNext.addEventListener("click", () => goToSlide(state.carousel.index + 1));
  el.btnSlideToggle.addEventListener("click", () => {
    state.carousel.paused = !state.carousel.paused;
    syncCarouselToggleUI();
    if (state.carousel.paused) stopCarouselTimer();
    else startCarouselTimer();
  });

  el.heroCarousel.addEventListener("mouseenter", () => {
    state.carousel.hoverPaused = true;
    stopCarouselTimer();
  });
  el.heroCarousel.addEventListener("mouseleave", () => {
    state.carousel.hoverPaused = false;
    startCarouselTimer();
  });
  el.heroCarousel.addEventListener("focusin", () => {
    state.carousel.focusPaused = true;
    stopCarouselTimer();
  });
  el.heroCarousel.addEventListener("focusout", (evt) => {
    if (!el.heroCarousel.contains(evt.relatedTarget)) {
      state.carousel.focusPaused = false;
      startCarouselTimer();
    }
  });
  el.heroCarousel.addEventListener("keydown", (evt) => {
    if (evt.key === "ArrowLeft") {
      evt.preventDefault();
      goToSlide(state.carousel.index - 1);
    } else if (evt.key === "ArrowRight") {
      evt.preventDefault();
      goToSlide(state.carousel.index + 1);
    }
  });

  prefersReducedMotion.addEventListener("change", (evt) => {
    if (evt.matches) {
      state.carousel.paused = true;
      syncCarouselToggleUI();
      stopCarouselTimer();
    }
  });

  // View switcher
  el.btnViewGrid.addEventListener("click", () => {
    state.viewMode = "grid";
    renderBooks();
  });
  el.btnViewTable.addEventListener("click", () => {
    state.viewMode = "table";
    renderBooks();
  });

  // Cover preview sync
  el.bookCoverSelect.addEventListener("change", () => {
    el.bookCover.value = el.bookCoverSelect.value;
    updateCoverPreview(el.bookCover.value);
  });
  el.bookCover.addEventListener("input", () => {
    updateCoverPreview(el.bookCover.value);
  });
  el.bookCoverPreviewImg.addEventListener("error", () => {
    el.bookCoverPreviewImg.classList.add("hidden");
    el.bookCoverPreviewEmpty.classList.remove("hidden");
  });

  // Auth & CTA triggers
  const openRegister = () => {
    el.registerForm.reset();
    setFormError(el.registerError, "");
    el.registerDialog.showModal();
  };

  el.btnOpenLogin.addEventListener("click", () => {
    el.loginForm.reset();
    setFormError(el.loginError, "");
    el.loginDialog.showModal();
  });
  el.btnOpenRegister.addEventListener("click", openRegister);
  el.btnCtaRegister.addEventListener("click", () => {
    if (state.user) openBookEditor(null);
    else openRegister();
  });
  el.btnHeroAdd.addEventListener("click", () => openBookEditor(null));
  el.btnAddBook.addEventListener("click", () => openBookEditor(null));

  el.btnLogout.addEventListener("click", async () => {
    try {
      await apiRequest("/api/auth/logout", { method: "POST" });
    } finally {
      state.user = null;
      renderAuthUI();
      showToast("Đã đăng xuất.", "success");
    }
  });

  el.loginForm.addEventListener("submit", async (evt) => {
    evt.preventDefault();
    setFormError(el.loginError, "");
    const formData = new FormData(el.loginForm);
    try {
      const result = await apiRequest("/api/auth/login", {
        method: "POST",
        body: JSON.stringify({
          username: String(formData.get("username") || "").trim(),
          password: String(formData.get("password") || ""),
        }),
      });
      state.user = result.user;
      renderAuthUI();
      el.loginDialog.close();
      showToast(`Chào mừng ${result.user.full_name}!`, "success");
    } catch (err) {
      setFormError(el.loginError, err.message);
    }
  });

  el.registerForm.addEventListener("submit", async (evt) => {
    evt.preventDefault();
    setFormError(el.registerError, "");
    const formData = new FormData(el.registerForm);
    try {
      const result = await apiRequest("/api/auth/register", {
        method: "POST",
        body: JSON.stringify({
          ho_ten: String(formData.get("ho_ten") || "").trim(),
          tai_khoan: String(formData.get("tai_khoan") || "").trim(),
          mat_khau: String(formData.get("mat_khau") || ""),
          email: String(formData.get("email") || "").trim(),
          dien_thoai: String(formData.get("dien_thoai") || "").trim() || null,
          dia_chi: String(formData.get("dia_chi") || "").trim() || null,
        }),
      });
      state.user = result.user;
      renderAuthUI();
      el.registerDialog.close();
      showToast("Đăng ký tài khoản thành công!", "success");
    } catch (err) {
      setFormError(el.registerError, err.message);
    }
  });

  el.bookForm.addEventListener("submit", async (evt) => {
    evt.preventDefault();
    setFormError(el.bookError, "");
    const maSach = el.bookId.value.trim();
    const payload = {
      TenSach: el.bookTitle.value.trim(),
      MaCD: Number(el.bookCategory.value),
      MaNXB: Number(el.bookPublisher.value),
      GiaBan: Number(el.bookPrice.value),
      SoLuongBan: Number(el.bookQty.value),
      AnhBia: el.bookCover.value.trim() || null,
      MoTa: el.bookDesc.value.trim() || null,
    };
    try {
      if (maSach) {
        await apiRequest(`/api/books/${maSach}`, {
          method: "PUT",
          body: JSON.stringify(payload),
        });
        showToast(`Đã cập nhật sách #${maSach}.`, "success");
      } else {
        await apiRequest("/api/books", {
          method: "POST",
          body: JSON.stringify(payload),
        });
        showToast("Đã thêm sách mới thành công!", "success");
        state.page = 1;
      }
      el.bookDialog.close();
      await Promise.all([loadBooks(), refreshHeroSummary()]);
    } catch (err) {
      setFormError(el.bookError, err.message);
    }
  });

  // Filters
  el.filterForm.addEventListener("submit", async (evt) => {
    evt.preventDefault();
    state.filters.q = el.searchInput.value.trim();
    state.filters.ma_cd = el.filterCategory.value;
    state.filters.ma_nxb = el.filterPublisher.value;
    state.page = 1;
    await loadBooks();
  });

  async function resetFilters() {
    el.filterForm.reset();
    state.filters = { q: "", ma_cd: "", ma_nxb: "" };
    state.page = 1;
    await loadBooks();
  }

  el.btnResetFilter.addEventListener("click", resetFilters);
  el.btnStateAction.addEventListener("click", async () => {
    if (el.btnStateAction.dataset.action === "retry") await loadBooks();
    else await resetFilters();
  });

  el.btnPrevPage.addEventListener("click", async () => {
    if (state.page > 1) {
      state.page -= 1;
      await loadBooks();
    }
  });

  el.btnNextPage.addEventListener("click", async () => {
    const totalPages = Math.ceil(state.total / state.pageSize);
    if (state.page < totalPages) {
      state.page += 1;
      await loadBooks();
    }
  });
}

async function init() {
  initMicroInteractions();
  bindEvents();
  await Promise.all([checkHealth(), restoreSession(), loadCatalogsAndMedia()]);
  await loadBooks();
}

document.addEventListener("DOMContentLoaded", init);
