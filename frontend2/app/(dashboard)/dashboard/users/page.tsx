"use client";

import { useEffect, useState } from "react";
import { useAuth } from "@/lib/auth-context";
import { usersApi, rolesApi, adminApi, type User, type Role } from "@/lib/api";
import { Loader2 } from "lucide-react";

export default function UsersPage() {
  const { user: currentUser, ready } = useAuth();
  const isAdmin = currentUser?.role === "admin";
  const [list, setList] = useState<User[]>([]);
  const [roles, setRoles] = useState<Role[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [modal, setModal] = useState<"create" | "edit" | null>(null);
  const [editing, setEditing] = useState<User | null>(null);
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [role, setRole] = useState("");
  const [submitLoading, setSubmitLoading] = useState(false);
  const [banningId, setBanningId] = useState<string | null>(null);

  function load() {
    setLoading(true);
    setError("");
    Promise.all([usersApi.list({ limit: 100 }), rolesApi.list()])
      .then(([usersRes, rolesRes]) => {
        setList(usersRes.data);
        setRoles(rolesRes.data);
        if (rolesRes.data.length && !role) setRole(rolesRes.data[0].name);
      })
      .catch((e) => setError(e instanceof Error ? e.message : "Failed to load"))
      .finally(() => setLoading(false));
  }

  useEffect(() => { load(); }, []);

  if (ready && !isAdmin) {
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
    setEmail("");
    setPassword("");
    setRole(roles[0]?.name ?? "");
    setModal("create");
  }
  function openEdit(u: User) {
    setEditing(u);
    setName(u.name);
    setEmail(u.email);
    setPassword("");
    setRole(typeof u.roleId === "object" && u.roleId ? u.roleId.name : (u.role ?? ""));
    setModal("edit");
  }
  function closeModal() {
    setModal(null);
    setEditing(null);
    setName("");
    setEmail("");
    setPassword("");
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!name.trim() || !email.trim()) return;
    if (!editing && !password) {
      setError("Password is required for new users");
      return;
    }
    if (!editing && password.length < 6) {
      setError("Password must be at least 6 characters");
      return;
    }
    setSubmitLoading(true);
    setError("");
    try {
      if (editing) {
        const body: Partial<User & { role: string }> = { name: name.trim(), email: email.trim(), role };
        if (password.trim()) body.password = password;
        await usersApi.update(editing._id, body);
      } else {
        await usersApi.create({ name: name.trim(), email: email.trim(), password, role });
      }
      closeModal();
      load();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed");
    } finally {
      setSubmitLoading(false);
    }
  }

  async function handleDelete(u: User) {
    if (!confirm(`Delete user "${u.email}"?`)) return;
    try {
      if (isAdmin) {
        await adminApi.deleteUser(u._id);
      } else {
        await usersApi.delete(u._id);
      }
      load();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to delete");
    }
  }

  async function handleBan(u: User, isBanned: boolean) {
    if (!isAdmin || currentUser?._id === u._id) return;
    if (!confirm(isBanned ? `Ban "${u.email}"?` : `Unban "${u.email}"?`)) return;
    setBanningId(u._id);
    try {
      await adminApi.banUser(u._id, isBanned);
      load();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to update ban");
    } finally {
      setBanningId(null);
    }
  }

  return (
    <div>
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-semibold text-slate-800">Users</h1>
        {roles.length === 0 ? (
          <p className="text-sm text-slate-500">Create a role first, then add users.</p>
        ) : (
          <button
            type="button"
            onClick={openCreate}
            className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700"
          >
            Add user
          </button>
        )}
      </div>
      {error && (
        <div className="mb-4 rounded-lg bg-red-50 px-4 py-2 text-sm text-red-700">{error}</div>
      )}
      {loading ? (
        <p className="text-slate-500">Loading…</p>
      ) : (
        <div className="overflow-hidden rounded-lg border border-slate-200 bg-white">
          <table className="w-full text-left text-sm">
            <thead className="border-b border-slate-200 bg-slate-50">
              <tr>
                <th className="px-4 py-3 font-medium text-slate-600">Name</th>
                <th className="px-4 py-3 font-medium text-slate-600">Email</th>
                <th className="px-4 py-3 font-medium text-slate-600">Role</th>
                {isAdmin && <th className="px-4 py-3 font-medium text-slate-600">Status</th>}
                <th className="px-4 py-3 font-medium text-slate-600">Actions</th>
              </tr>
            </thead>
            <tbody>
              {list.map((u) => (
                <tr key={u._id} className="border-b border-slate-100">
                  <td className="px-4 py-3">{u.name}</td>
                  <td className="px-4 py-3">{u.email}</td>
                  <td className="px-4 py-3">
                    {typeof u.roleId === "object" && u.roleId ? u.roleId.name : u.role ?? "—"}
                  </td>
                  {isAdmin && (
                    <td className="px-4 py-3">
                      {u.isBanned ? (
                        <span className="rounded-full bg-red-100 px-2 py-0.5 text-xs font-medium text-red-800">Banned</span>
                      ) : (
                        <span className="text-slate-500">Active</span>
                      )}
                    </td>
                  )}
                  <td className="px-4 py-3">
                    <button type="button" onClick={() => openEdit(u)} className="mr-2 text-blue-600 hover:underline">Edit</button>
                    {isAdmin && currentUser?._id !== u._id && (
                      <button
                        type="button"
                        onClick={() => handleBan(u, !u.isBanned)}
                        disabled={banningId === u._id}
                        className="mr-2 inline-flex items-center gap-1 text-amber-600 hover:underline disabled:opacity-50"
                      >
                        {banningId === u._id && <Loader2 className="h-4 w-4 animate-spin" aria-hidden />}
                        {u.isBanned ? "Unban" : "Ban"}
                      </button>
                    )}
                    <button type="button" onClick={() => handleDelete(u)} className="text-red-600 hover:underline">Delete</button>
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
            <h2 className="mb-4 text-lg font-semibold">{editing ? "Edit user" : "Create user"}</h2>
            <form onSubmit={handleSubmit} className="flex flex-col gap-4">
              <div>
                <label className="mb-1 block text-sm font-medium text-slate-600">Name</label>
                <input type="text" value={name} onChange={(e) => setName(e.target.value)} className="w-full rounded-lg border border-slate-300 px-3 py-2" required />
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium text-slate-600">Email</label>
                <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} className="w-full rounded-lg border border-slate-300 px-3 py-2" required disabled={!!editing} />
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium text-slate-600">Password</label>
                <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} className="w-full rounded-lg border border-slate-300 px-3 py-2" minLength={6} placeholder={editing ? "Leave blank to keep" : ""} />
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium text-slate-600">Role</label>
                <select value={role} onChange={(e) => setRole(e.target.value)} className="w-full rounded-lg border border-slate-300 px-3 py-2">
                  {roles.map((r) => (
                    <option key={r._id} value={r.name}>{r.name}</option>
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
