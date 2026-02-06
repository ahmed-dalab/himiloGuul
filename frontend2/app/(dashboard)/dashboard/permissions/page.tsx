"use client";

import { useEffect, useState } from "react";
import { useAuth } from "@/lib/auth-context";
import { permissionsApi, menusApi, type Permission, type Menu } from "@/lib/api";

function menuLabel(p: Permission): string {
  const m = p.menuId;
  if (typeof m === "object" && m && "path" in m) return (m as { path?: string }).path ?? (m as { name?: string }).name ?? "—";
  return "—";
}

export default function PermissionsPage() {
  const { user, ready } = useAuth();
  const [list, setList] = useState<Permission[]>([]);
  const [menus, setMenus] = useState<Menu[]>([]);
  const [filterMenuId, setFilterMenuId] = useState<string>("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [modal, setModal] = useState<"create" | "edit" | null>(null);
  const [editing, setEditing] = useState<Permission | null>(null);
  const [name, setName] = useState("");
  const [menuId, setMenuId] = useState("");
  const [submitLoading, setSubmitLoading] = useState(false);

  function load() {
    setLoading(true);
    setError("");
    const params = { limit: "100" };
    if (filterMenuId) params.menuId = filterMenuId;
    permissionsApi
      .list({ limit: 100, menuId: filterMenuId || undefined })
      .then((r) => setList(r.data))
      .catch((e) => setError(e instanceof Error ? e.message : "Failed to load"))
      .finally(() => setLoading(false));
  }

  useEffect(() => { load(); }, [filterMenuId]);

  useEffect(() => {
    menusApi.list().then((r) => setMenus(r.menus)).catch(() => setMenus([]));
  }, []);

  if (ready && user?.role !== "admin") {
    return (
      <div className="rounded-xl border border-amber-200 bg-amber-50 px-4 py-6 text-amber-800">
        <p className="font-medium">Access denied.</p>
        <p className="mt-1 text-sm">This page is for administrators only.</p>
      </div>
    );
  }

  function openCreate() {
    setEditing(null);
    setName("");
    setMenuId(menus[0]?._id ?? "");
    setModal("create");
  }
  function openEdit(p: Permission) {
    setEditing(p);
    setName(p.name);
    const mid = typeof p.menuId === "object" && p.menuId && "_id" in p.menuId ? (p.menuId as { _id: string })._id : (p.menuId as string);
    setMenuId(mid ?? "");
    setModal("edit");
  }
  function closeModal() {
    setModal(null);
    setEditing(null);
    setName("");
    setMenuId("");
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!name.trim() || !menuId) return;
    setSubmitLoading(true);
    try {
      if (editing) await permissionsApi.update(editing._id, { name: name.trim(), menuId });
      else await permissionsApi.create({ name: name.trim(), menuId });
      closeModal();
      load();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed");
    } finally {
      setSubmitLoading(false);
    }
  }

  async function handleDelete(p: Permission) {
    if (!confirm(`Delete permission "${p.name}"?`)) return;
    try {
      await permissionsApi.delete(p._id);
      load();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to delete");
    }
  }

  return (
    <div>
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-semibold text-slate-800">Permissions</h1>
        {menus.length === 0 ? (
          <p className="text-sm text-slate-500">Create a menu first, then add permissions.</p>
        ) : (
          <button type="button" onClick={openCreate} className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700">
            Add permission
          </button>
        )}
      </div>
      <div className="mb-4">
        <label className="mb-1 block text-sm font-medium text-slate-600">Filter by menu</label>
        <select
          value={filterMenuId}
          onChange={(e) => setFilterMenuId(e.target.value)}
          className="rounded-lg border border-slate-300 px-3 py-2 text-sm"
        >
          <option value="">All menus</option>
          {menus.map((m) => (
            <option key={m._id} value={m._id}>{m.name} ({m.path})</option>
          ))}
        </select>
      </div>
      {error && <div className="mb-4 rounded-lg bg-red-50 px-4 py-2 text-sm text-red-700">{error}</div>}
      {loading ? (
        <p className="text-slate-500">Loading…</p>
      ) : (
        <div className="overflow-hidden rounded-lg border border-slate-200 bg-white">
          <table className="w-full text-left text-sm">
            <thead className="border-b border-slate-200 bg-slate-50">
              <tr>
                <th className="px-4 py-3 font-medium text-slate-600">Name</th>
                <th className="px-4 py-3 font-medium text-slate-600">Menu</th>
                <th className="px-4 py-3 font-medium text-slate-600">Actions</th>
              </tr>
            </thead>
            <tbody>
              {list.map((p) => (
                <tr key={p._id} className="border-b border-slate-100">
                  <td className="px-4 py-3">{p.name}</td>
                  <td className="px-4 py-3 text-slate-600">{menuLabel(p)}</td>
                  <td className="px-4 py-3">
                    <button type="button" onClick={() => openEdit(p)} className="mr-2 text-blue-600 hover:underline">Edit</button>
                    <button type="button" onClick={() => handleDelete(p)} className="text-red-600 hover:underline">Delete</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {modal && (
        <div className="fixed inset-0 z-10 flex items-center justify-center bg-black/40" onClick={closeModal}>
          <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-lg" onClick={(e) => e.stopPropagation()}>
            <h2 className="mb-4 text-lg font-semibold">{editing ? "Edit permission" : "Create permission"}</h2>
            <form onSubmit={handleSubmit} className="flex flex-col gap-4">
              <div>
                <label className="mb-1 block text-sm font-medium text-slate-600">Name</label>
                <input type="text" value={name} onChange={(e) => setName(e.target.value)} className="w-full rounded-lg border border-slate-300 px-3 py-2" required />
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium text-slate-600">Menu (required)</label>
                <select value={menuId} onChange={(e) => setMenuId(e.target.value)} className="w-full rounded-lg border border-slate-300 px-3 py-2" required>
                  <option value="">Select menu</option>
                  {menus.map((m) => (
                    <option key={m._id} value={m._id}>{m.name} — {m.path}</option>
                  ))}
                </select>
              </div>
              <div className="flex gap-2">
                <button type="button" onClick={closeModal} className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium">Cancel</button>
                <button type="submit" disabled={submitLoading} className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50">
                  {submitLoading ? "Saving…" : editing ? "Save" : "Create"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
