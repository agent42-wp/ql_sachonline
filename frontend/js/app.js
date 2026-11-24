"use strict";

const state = {
  user: null,
  categories: [],
  publishers: [],
  books: [],
  page: 1,
  pageSize: 10,
  total: 0,
  filters: {
    q: "",
    ma_cd: "",
    ma_nxb: "",
  },
};

const el = {
  healthPill: document.getElementById("health-pill"),
  guestActions: document.getElementById("guest-actions"),
  userActions: document.getElementById("user-actions"),
  userName: document.getElementById("user-name"),
  userRole: document.getElementById("user-role"),
  authHint: document.getElementById("auth-hint"),
  statBooks: document.getElementById("stat-total-books"),
  statCategories: document.getElementById("stat-total-categories"),
  statPublishers: document.getElementById("stat-total-publishers"),
  filterForm: document.getElementById("filter-form"),
  searchInput: document.getElementById("search-input"),
  filterCategory: document.getElementById("filter-category"),
  filterPublisher: document.getElementById("filter-publisher"),
  booksTbody: document.getElementById("books-tbody"),
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
  bookCover: document.getElementById("book-cover"),
  bookDesc: document.getElementById("book-desc"),
  detailDialog: document.getElementById("detail-dialog"),
  detailTitle: document.getElementById("detail-title"),
  detailBody: document.getElementById("detail-body"),
  toastRegion: document.getElementById("toast-region"),
};

function formatCurrency(amount) {
  return new Intl.NumberFormat("vi-VN").format(Number(amount || 0)) + " đ";
}

function showToast(message, type = "info") {
  const toast = document.createElement("div");
  toast.className = `toast ${type === "success" ? "toast-success" : type === "error" ? "toast-error" : ""}`;
  toast.textContent = message;
  el.toastRegion.appendChild(toast);
  setTimeout(() => toast.remove(), 3500);
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

function renderBooksTable() {
  el.booksTbody.replaceChildren();
  if (!state.books.length) {
    const tr = document.createElement("tr");
    const td = document.createElement("td");
    td.colSpan = 7;
    td.className = "empty-cell";
    td.textContent = "Không tìm thấy cuốn sách nào phù hợp.";
    tr.appendChild(td);
    el.booksTbody.appendChild(tr);
  } else {
    for (const book of state.books) {
      const tr = document.createElement("tr");

      const tdId = document.createElement("td");
      tdId.textContent = `#${book.MaSach}`;

      const tdName = document.createElement("td");
      tdName.className = "book-name-cell";
      tdName.textContent = book.TenSach;

      const tdCat = document.createElement("td");
      tdCat.textContent = book.TenChuDe || "—";

      const tdPub = document.createElement("td");
      tdPub.textContent = book.TenNXB || "—";

      const tdPrice = document.createElement("td");
      tdPrice.className = "num";
      tdPrice.textContent = formatCurrency(book.GiaBan);

      const tdQty = document.createElement("td");
      tdQty.className = "num";
      tdQty.textContent = String(book.SoLuongBan);

      const tdActions = document.createElement("td");
      const actionBox = document.createElement("div");
      actionBox.className = "row-actions";

      const btnView = document.createElement("button");
      btnView.type = "button";
      btnView.className = "btn btn-secondary btn-sm";
      btnView.textContent = "Xem";
      btnView.addEventListener("click", () => openBookDetail(book.MaSach));

      const btnEdit = document.createElement("button");
      btnEdit.type = "button";
      btnEdit.className = "btn btn-secondary btn-sm";
      btnEdit.textContent = "Sửa";
      btnEdit.addEventListener("click", () => openBookEditor(book));

      const btnDelete = document.createElement("button");
      btnDelete.type = "button";
      btnDelete.className = "btn btn-danger btn-sm";
      btnDelete.textContent = "Xóa";
      btnDelete.addEventListener("click", () => handleDeleteBook(book));

      actionBox.append(btnView, btnEdit, btnDelete);
      tdActions.appendChild(actionBox);

      tr.append(tdId, tdName, tdCat, tdPub, tdPrice, tdQty, tdActions);
      el.booksTbody.appendChild(tr);
    }
  }

  const totalPages = Math.max(1, Math.ceil(state.total / state.pageSize));
  el.paginationInfo.textContent = `Hiển thị ${state.books.length} / ${state.total} cuốn sách`;
  el.pageIndicator.textContent = `Trang ${state.page} / ${totalPages}`;
  el.btnPrevPage.disabled = state.page <= 1;
  el.btnNextPage.disabled = state.page >= totalPages;
}

async function checkHealth() {
  try {
    await apiRequest("/api/health");
    el.healthPill.textContent = "API & MariaDB: Hoạt động";
    el.healthPill.className = "status-pill status-ok";
  } catch {
    el.healthPill.textContent = "Mất kết nối API";
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

async function loadCatalogs() {
  const [categories, publishers] = await Promise.all([
    apiRequest("/api/categories"),
    apiRequest("/api/publishers"),
  ]);
  state.categories = categories;
  state.publishers = publishers;

  el.statCategories.textContent = String(categories.length);
  el.statPublishers.textContent = String(publishers.length);

  populateSelect(el.filterCategory, categories, "MaCD", "TenChuDe", "Tất cả chủ đề");
  populateSelect(el.filterPublisher, publishers, "MaNXB", "TenNXB", "Tất cả NXB");
  populateSelect(el.bookCategory, categories, "MaCD", "TenChuDe", null);
  populateSelect(el.bookPublisher, publishers, "MaNXB", "TenNXB", null);
}

async function loadBooks() {
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
    renderBooksTable();
  } catch (err) {
    showToast(err.message, "error");
  }
}

async function openBookDetail(maSach) {
  try {
    const book = await apiRequest(`/api/books/${maSach}`);
    el.detailTitle.textContent = `Chi tiết sách #${book.MaSach}`;
    el.detailBody.replaceChildren();

    const heading = document.createElement("h4");
    heading.style.margin = "0";
    heading.textContent = book.TenSach;

    const metaGrid = document.createElement("div");
    metaGrid.className = "detail-meta";
    const metaRows = [
      ["Chủ đề", book.TenChuDe || "—"],
      ["Nhà xuất bản", book.TenNXB || "—"],
      ["Giá bán", formatCurrency(book.GiaBan)],
      ["Số lượng bán", String(book.SoLuongBan)],
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
    desc.textContent = book.MoTa && book.MoTa.trim() ? book.MoTa : "Chưa có mô tả chi tiết cho cuốn sách này.";

    el.detailBody.append(heading, metaGrid, desc);
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
  }
  el.bookDialog.showModal();
}

async function handleDeleteBook(book) {
  if (!state.user) {
    showToast("Vui lòng đăng nhập để xóa sách.", "error");
    el.loginDialog.showModal();
    return;
  }
  const confirmed = window.confirm(`Bạn có chắc chắn muốn xóa cuốn sách "${book.TenSach}" (#${book.MaSach})?`);
  if (!confirmed) return;

  try {
    await apiRequest(`/api/books/${book.MaSach}`, { method: "DELETE" });
    showToast(`Đã xóa sách #${book.MaSach}.`, "success");
    await loadBooks();
  } catch (err) {
    showToast(err.message, "error");
  }
}

function bindEvents() {
  document.querySelectorAll("[data-close-dialog]").forEach((btn) => {
    btn.addEventListener("click", () => {
      const target = document.getElementById(btn.getAttribute("data-close-dialog"));
      if (target) target.close();
    });
  });

  el.btnOpenLogin.addEventListener("click", () => {
    el.loginForm.reset();
    setFormError(el.loginError, "");
    el.loginDialog.showModal();
  });

  el.btnOpenRegister.addEventListener("click", () => {
    el.registerForm.reset();
    setFormError(el.registerError, "");
    el.registerDialog.showModal();
  });

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
      await loadBooks();
    } catch (err) {
      setFormError(el.bookError, err.message);
    }
  });

  el.filterForm.addEventListener("submit", async (evt) => {
    evt.preventDefault();
    state.filters.q = el.searchInput.value.trim();
    state.filters.ma_cd = el.filterCategory.value;
    state.filters.ma_nxb = el.filterPublisher.value;
    state.page = 1;
    await loadBooks();
  });

  el.btnResetFilter.addEventListener("click", async () => {
    el.filterForm.reset();
    state.filters = { q: "", ma_cd: "", ma_nxb: "" };
    state.page = 1;
    await loadBooks();
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
  bindEvents();
  await Promise.all([checkHealth(), restoreSession(), loadCatalogs()]);
  await loadBooks();
}

document.addEventListener("DOMContentLoaded", init);
