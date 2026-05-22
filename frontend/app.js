/**
 * 天猫员工请假管理 — 前端逻辑
 * 依赖：后端 FastAPI 已开启 CORS（见 backend/app/main.py）
 */

const STORAGE_KEY = "tmall_attendance_api_base";
const DEFAULT_API_BASE = "http://127.0.0.1:8000";

function normalizeApiBase(value) {
  const raw = String(value || "").trim();
  if (!raw) return DEFAULT_API_BASE;

  try {
    const url = new URL(raw);
    if (url.port === "5500" || url.port === "5173" || url.port === "3000") return DEFAULT_API_BASE;
    if (url.pathname === "/" || url.pathname === "") return url.origin;
    if (url.pathname.startsWith("/docs") || url.pathname.startsWith("/redoc") || url.pathname.startsWith("/openapi.json")) {
      return url.origin;
    }
  } catch {
    return raw.replace(/\/$/, "");
  }

  return raw.replace(/\/$/, "");
}

function getApiBase() {
  const input = document.getElementById("apiBase");
  const fromStorage = localStorage.getItem(STORAGE_KEY);
  return normalizeApiBase(input.value || fromStorage || DEFAULT_API_BASE);
}

function setApiStatus(msg, ok = true) {
  const el = document.getElementById("apiStatus");
  el.textContent = msg;
  el.className = ok ? "text-xs text-emerald-600" : "text-xs text-rose-600";
}

function showToast(message, ok = true) {
  const host = document.getElementById("toast");
  host.innerHTML = `
    <div class="pointer-events-auto max-w-md rounded-xl border px-4 py-3 text-sm shadow-lg ${
      ok ? "border-emerald-200 bg-emerald-50 text-emerald-900" : "border-rose-200 bg-rose-50 text-rose-900"
    }">
      ${escapeHtml(message)}
    </div>`;
  host.classList.remove("opacity-0");
  host.classList.add("opacity-100");
  clearTimeout(showToast._t);
  showToast._t = setTimeout(() => {
    host.classList.add("opacity-0");
    host.classList.remove("opacity-100");
  }, 3200);
}

function escapeHtml(s) {
  return String(s)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

async function apiFetch(path, options = {}) {
  const base = getApiBase();
  const url = `${base}${path.startsWith("/") ? path : `/${path}`}`;
  const headers = { "Content-Type": "application/json", ...(options.headers || {}) };
  const res = await fetch(url, { ...options, headers });
  const text = await res.text();
  let data = null;
  try {
    data = text ? JSON.parse(text) : null;
  } catch {
    data = { detail: text || res.statusText };
  }
  if (!res.ok) {
    const detail = data?.detail ?? data?.message ?? (text || res.statusText);
    const err = new Error(typeof detail === "string" ? detail : JSON.stringify(detail));
    err.status = res.status;
    err.body = data;
    throw err;
  }
  return data;
}

function currentEmpId() {
  const manual = document.getElementById("empIdInput").value.trim();
  if (manual) return parseInt(manual, 10);
  const sel = document.getElementById("empSelect").value;
  return sel ? parseInt(sel, 10) : NaN;
}

function syncEmpInputsFromSelect() {
  const sel = document.getElementById("empSelect");
  if (sel.value) document.getElementById("empIdInput").value = sel.value;
}

function statusBadge(status) {
  const map = {
    PENDING: "bg-amber-100 text-amber-800",
    APPROVED: "bg-emerald-100 text-emerald-800",
    REJECTED: "bg-rose-100 text-rose-800",
    CANCELLED: "bg-slate-100 text-slate-600",
  };
  const cls = map[status] || "bg-slate-100 text-slate-700";
  return `<span class="inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${cls}">${escapeHtml(status)}</span>`;
}

function formatRange(startAt, endAt) {
  const s = startAt ? String(startAt).slice(0, 16).replace("T", " ") : "";
  const e = endAt ? String(endAt).slice(0, 16).replace("T", " ") : "";
  return `${escapeHtml(s)} ~ ${escapeHtml(e)}`;
}

async function loadEmployeesAndDepartments() {
  const empSelect = document.getElementById("empSelect");
  const deptFilter = document.getElementById("deptFilter");
  empSelect.innerHTML = `<option value="">正在连接后端...</option>`;
  deptFilter.innerHTML = `<option value="">正在加载部门...</option>`;

  const [emps, depts] = await Promise.all([apiFetch("/employees"), apiFetch("/departments")]);

  empSelect.innerHTML = emps.length
    ? emps
        .map(
          (e) =>
            `<option value="${e.emp_id}">${escapeHtml(e.emp_no)} · ${escapeHtml(e.full_name)} (id=${e.emp_id})</option>`
        )
        .join("")
    : `<option value="">（无员工数据）</option>`;
  if (emps[0]) {
    empSelect.value = String(emps[0].emp_id);
    document.getElementById("empIdInput").value = String(emps[0].emp_id);
  }

  const first = `<option value="">全公司待审批</option>`;
  deptFilter.innerHTML =
    first +
    depts
      .map((d) => `<option value="${d.dept_id}">${escapeHtml(d.dept_name)} (id=${d.dept_id})</option>`)
      .join("");
}

async function loadMyHistory() {
  const empId = currentEmpId();
  const empty = document.getElementById("historyEmpty");
  if (!empId || Number.isNaN(empId)) {
    const msg = "请先选择或填写 emp_id";
    empty.textContent = msg;
    empty.classList.remove("hidden");
    showToast(msg, false);
    return;
  }
  empty.textContent = `正在加载 emp_id=${empId} 的请假历史...`;
  empty.classList.remove("hidden");
  const rows = await apiFetch(`/leave-applications?emp_id=${empId}&limit=200`);
  const tbody = document.getElementById("historyBody");
  tbody.innerHTML = "";
  if (!rows.length) {
    empty.textContent = `emp_id=${empId} 暂无请假记录`;
    empty.classList.remove("hidden");
    setApiStatus(`后端连接正常；emp_id=${empId} 历史记录 0 条`, true);
    return;
  }
  empty.classList.add("hidden");
  for (const r of rows) {
    const tr = document.createElement("tr");
    tr.className = "hover:bg-slate-50/80";
    tr.innerHTML = `
      <td class="whitespace-nowrap px-3 py-2 font-mono text-xs text-slate-600">#${r.application_id}</td>
      <td class="px-3 py-2">${escapeHtml(r.leave_type_name)}</td>
      <td class="px-3 py-2 text-xs text-slate-600">${formatRange(r.start_at, r.end_at)}</td>
      <td class="px-3 py-2">${statusBadge(r.approval_status)}</td>`;
    tbody.appendChild(tr);
  }
  setApiStatus(`后端连接正常；emp_id=${empId} 历史记录 ${rows.length} 条`, true);
}

async function loadPending() {
  const deptId = document.getElementById("deptFilter").value;
  let path = "/leave-applications?approval_status=PENDING&limit=200";
  if (deptId) path += `&dept_id=${encodeURIComponent(deptId)}`;
  const rows = await apiFetch(path);
  const tbody = document.getElementById("pendingBody");
  const empty = document.getElementById("pendingEmpty");
  tbody.innerHTML = "";
  if (!rows.length) {
    empty.classList.remove("hidden");
    return;
  }
  empty.classList.add("hidden");
  for (const r of rows) {
    const tr = document.createElement("tr");
    tr.className = "hover:bg-slate-50/80";
    tr.innerHTML = `
      <td class="whitespace-nowrap px-3 py-2 font-mono text-xs text-slate-600">#${r.application_id}</td>
      <td class="px-3 py-2">
        <div class="font-medium text-slate-800">${escapeHtml(r.full_name)}</div>
        <div class="text-xs text-slate-500">${escapeHtml(r.emp_no)} · emp_id=${r.emp_id}</div>
      </td>
      <td class="px-3 py-2">${escapeHtml(r.leave_type_name)}</td>
      <td class="px-3 py-2 text-xs text-slate-600">${formatRange(r.start_at, r.end_at)}</td>
      <td class="max-w-xs truncate px-3 py-2 text-xs text-slate-600" title="${escapeHtml(r.reason)}">${escapeHtml(r.reason)}</td>
      <td class="whitespace-nowrap px-3 py-2">
        <button type="button" data-action="approve" data-id="${r.application_id}" class="mr-1 rounded-lg bg-emerald-600 px-2 py-1 text-xs font-semibold text-white hover:bg-emerald-700">同意</button>
        <button type="button" data-action="reject" data-id="${r.application_id}" class="rounded-lg bg-rose-600 px-2 py-1 text-xs font-semibold text-white hover:bg-rose-700">驳回</button>
      </td>`;
    tbody.appendChild(tr);
  }
}

async function reviewApplication(applicationId, status) {
  const comment = window.prompt(status === "APPROVED" ? "审批意见（可留空）" : "驳回原因（可留空）", "") ?? "";
  await apiFetch(`/leave-applications/${applicationId}/review`, {
    method: "PATCH",
    body: JSON.stringify({ status, comment: comment.trim() || null }),
  });
  showToast(status === "APPROVED" ? "已通过" : "已驳回", true);
  await loadPending();
  await loadMyHistory();
}

function wireEvents() {
  document.getElementById("saveApiBase").addEventListener("click", () => {
    const v = normalizeApiBase(document.getElementById("apiBase").value);
    document.getElementById("apiBase").value = v;
    localStorage.setItem(STORAGE_KEY, v);
    showToast("已保存 API 地址", true);
    setApiStatus(`已保存 API 地址：${v}`, true);
  });

  document.getElementById("empSelect").addEventListener("change", () => {
    syncEmpInputsFromSelect();
  });

  document.getElementById("refreshHistory").addEventListener("click", () =>
    loadMyHistory().catch((e) => {
      const empty = document.getElementById("historyEmpty");
      empty.textContent = `加载失败：${e.message}`;
      empty.classList.remove("hidden");
      setApiStatus(`请求失败：${getApiBase()}`, false);
      showToast(e.message, false);
    })
  );

  document.getElementById("refreshPending").addEventListener("click", () => loadPending().catch((e) => showToast(e.message, false)));

  document.getElementById("deptFilter").addEventListener("change", () => loadPending().catch((e) => showToast(e.message, false)));

  document.getElementById("leaveForm").addEventListener("submit", async (ev) => {
    ev.preventDefault();
    const empId = currentEmpId();
    if (!empId || Number.isNaN(empId)) {
      showToast("请选择或填写 emp_id", false);
      return;
    }
    const payload = {
      emp_id: empId,
      leave_type_code: document.getElementById("leaveType").value,
      start_date: document.getElementById("startDate").value,
      end_date: document.getElementById("endDate").value,
      reason: document.getElementById("reason").value,
    };
    const attachmentInput = document.getElementById("attachmentUrl");
    const att = attachmentInput ? attachmentInput.value.trim() : "";
    if (att) payload.attachment_url = att;
    try {
      await apiFetch("/leave-applications", { method: "POST", body: JSON.stringify(payload) });
      showToast("提交成功", true);
      document.getElementById("reason").value = "";
      if (attachmentInput) attachmentInput.value = "";
      await Promise.all([loadMyHistory(), loadPending()]);
    } catch (e) {
      showToast(e.message || "提交失败", false);
    }
  });

  document.getElementById("pendingBody").addEventListener("click", async (ev) => {
    const btn = ev.target.closest("button[data-action]");
    if (!btn) return;
    const id = parseInt(btn.getAttribute("data-id"), 10);
    const action = btn.getAttribute("data-action");
    const status = action === "approve" ? "APPROVED" : "REJECTED";
    try {
      await reviewApplication(id, status);
    } catch (e) {
      showToast(e.message || "操作失败", false);
    }
  });
}

async function pingHealth() {
  try {
    await apiFetch("/health");
    setApiStatus("后端连接正常", true);
  } catch {
    setApiStatus("无法连接后端，请检查地址与 uvicorn 是否已启动", false);
  }
}

async function init() {
  const input = document.getElementById("apiBase");
  input.value = normalizeApiBase(localStorage.getItem(STORAGE_KEY) || DEFAULT_API_BASE);
  localStorage.setItem(STORAGE_KEY, input.value);

  wireEvents();

  try {
    await pingHealth();
    await loadEmployeesAndDepartments();
    await Promise.all([loadMyHistory(), loadPending()]);
    showToast("数据已加载", true);
  } catch (e) {
    const empSelect = document.getElementById("empSelect");
    const historyEmpty = document.getElementById("historyEmpty");
    empSelect.innerHTML = `<option value="">员工加载失败</option>`;
    historyEmpty.textContent = `加载失败：${e.message}`;
    historyEmpty.classList.remove("hidden");
    setApiStatus(`连接失败，当前 API：${getApiBase()}`, false);
    showToast(e.message || "初始化失败：请确认 API 地址与后端服务", false);
  }
}

document.addEventListener("DOMContentLoaded", init);
