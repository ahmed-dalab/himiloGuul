"use client";

import { useEffect, useState } from "react";
import { useAuth } from "@/lib/auth-context";
import { menusApi, type Menu } from "@/lib/api";

export default function MenusPage() {
  const { user, ready } = useAuth();
  const [list, setList] = useState<Menu[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [modal, setModal] = useState<"create" | "edit" | null>(null);
  const [editing, setEditing] = useState<Menu | null>(null);
  const [name, setName] = useState("");
  const [path, setPath] = useState("");
  const [submitLoading, setSubmitLoading] = useState(false);

  function load() {
    setLoading(true);
    setError("");
    menusApi
      .list()
      .then((r) => setList(r.menus))
      .catch((e) => setError(e instanceof Error ? e.message : "Failed to load"))
      .finally(() => setLoading(false));
  }

  useEffect(() => { load(); }, []);

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
    setPath("");
    setModal("create");
  }
  function openEdit(m: Menu) {
    setEditing(m);
    setName(m.name);
    setPath(m.path);
    setModal("edit");
  }
  function closeModal() {
    setModal(null);
    setEditing(null);
    setName("");
    setPath("");
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!name.trim() || !path.trim()) return;
    setSubmitLoading(true);
    try {
      if (editing) await menusApi.update(editing._id, { name: name.trim(), path: path.trim() });
      else await menusApi.create({ name: name.trim(), path: path.trim() });
      closeModal();
      load();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed");
    } finally {
      setSubmitLoading(false);
    }
  }

  async function handleDelete(m: Menu) {
    if (!confirm(`Delete menu "${m.name}" (${m.path})?`)) return;
    try {
      await menusApi.delete(m._id);
      load();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to delete");
    }
  }

  return (
    <div>
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-semibold text-slate-800">Menus</h1>
        <button type="button" onClick={openCreate} className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700">
          Add menu
        </button>
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
                <th className="px-4 py-3 font-medium text-slate-600">Path</th>
                <th className="px-4 py-3 font-medium text-slate-600">Actions</th>
              </tr>
            </thead>
            <tbody>
              {list.map((m) => (
                <tr key={m._id} className="border-b border-slate-100">
                  <td className="px-4 py-3">{m.name}</td>
                  <td className="px-4 py-3 font-mono text-slate-600">{m.path}</td>
                  <td className="px-4 py-3">
                    <button type="button" onClick={() => openEdit(m)} className="mr-2 text-blue-600 hover:underline">Edit</button>
                    <button type="button" onClick={() => handleDelete(m)} className="text-red-600 hover:underline">Delete</button>
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
            <h2 className="mb-4 text-lg font-semibold">{editing ? "Edit menu" : "Create menu"}</h2>
            <form onSubmit={handleSubmit} className="flex flex-col gap-4">
              <div>
                <label className="mb-1 block text-sm font-medium text-slate-600">Name</label>
                <input type="text" value={name} onChange={(e) => setName(e.target.value)} className="w-full rounded-lg border border-slate-300 px-3 py-2" required />
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium text-slate-600">Path</label>
                <input type="text" value={path} onChange={(e) => setPath(e.target.value)} className="w-full rounded-lg border border-slate-300 px-3 py-2" placeholder="/admin/users" required />
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
