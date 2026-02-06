"use client";

import { useEffect, useState } from "react";
import { useAuth } from "@/lib/auth-context";
import { rolePermissionsApi, rolesApi, permissionsApi, type Role, type Permission, type RolePermission } from "@/lib/api";

function roleName(rp: RolePermission): string {
  const r = rp.roleId;
  return typeof r === "object" && r && "name" in r ? (r as { name: string }).name : "—";
}
function permName(rp: RolePermission): string {
  const p = rp.permissionId;
  return typeof p === "object" && p && "name" in p ? (p as { name: string }).name : "—";
}
function permMenu(rp: RolePermission): string {
  const p = rp.permissionId;
  if (typeof p !== "object" || !p || !("menuId" in p)) return "—";
  const m = (p as { menuId?: { path?: string; name?: string } }).menuId;
  if (typeof m === "object" && m) return m.path ?? m.name ?? "—";
  return "—";
}

export default function RolePermissionsPage() {
  const { user, ready } = useAuth();
  const [list, setList] = useState<RolePermission[]>([]);
  const [roles, setRoles] = useState<Role[]>([]);
  const [permissions, setPermissions] = useState<Permission[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [modal, setModal] = useState(false);
  const [selectedRoleId, setSelectedRoleId] = useState("");
  const [selectedPermissionId, setSelectedPermissionId] = useState("");
  const [submitLoading, setSubmitLoading] = useState(false);

  function load() {
    setLoading(true);
    setError("");
    rolePermissionsApi
      .list({ limit: 500 })
      .then((r) => setList(r.data))
      .catch((e) => setError(e instanceof Error ? e.message : "Failed to load"))
      .finally(() => setLoading(false));
  }

  useEffect(() => { load(); }, []);

  useEffect(() => {
    Promise.all([rolesApi.list(), permissionsApi.list({ limit: 500 })])
      .then(([rolesRes, permRes]) => {
        setRoles(rolesRes.data);
        setPermissions(permRes.data);
        if (!selectedRoleId && rolesRes.data.length) setSelectedRoleId(rolesRes.data[0]._id);
        if (!selectedPermissionId && permRes.data.length) setSelectedPermissionId(permRes.data[0]._id);
      })
      .catch(() => {});
  }, []);

  if (ready && user?.role !== "admin") {
    return (
      <div className="rounded-xl border border-amber-200 bg-amber-50 px-4 py-6 text-amber-800">
        <p className="font-medium">Access denied.</p>
        <p className="mt-1 text-sm">This page is for administrators only.</p>
      </div>
    );
  }

  const alreadyAssigned = list.some(
    (rp) =>
      (typeof rp.roleId === "object" ? (rp.roleId as { _id: string })._id : rp.roleId) === selectedRoleId &&
      (typeof rp.permissionId === "object" ? (rp.permissionId as { _id: string })._id : rp.permissionId) === selectedPermissionId
  );

  function openAssign() {
    setSelectedRoleId(roles[0]?._id ?? "");
    setSelectedPermissionId(permissions[0]?._id ?? "");
    setModal(true);
  }

  async function handleAssign(e: React.FormEvent) {
    e.preventDefault();
    if (!selectedRoleId || !selectedPermissionId || alreadyAssigned) return;
    setSubmitLoading(true);
    try {
      await rolePermissionsApi.create({ roleId: selectedRoleId, permissionId: selectedPermissionId });
      setModal(false);
      load();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to assign");
    } finally {
      setSubmitLoading(false);
    }
  }

  async function handleRemove(rp: RolePermission) {
    const roleId = typeof rp.roleId === "object" && rp.roleId ? (rp.roleId as { _id: string })._id : rp.roleId;
    const permissionId = typeof rp.permissionId === "object" && rp.permissionId ? (rp.permissionId as { _id: string })._id : rp.permissionId;
    if (!confirm(`Remove this assignment?`)) return;
    try {
      await rolePermissionsApi.delete(roleId, permissionId);
      load();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to remove");
    }
  }

  return (
    <div>
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-semibold text-slate-800">Role Permissions</h1>
        {roles.length === 0 || permissions.length === 0 ? (
          <p className="text-sm text-slate-500">
            Create at least one role and one permission first.
          </p>
        ) : (
          <button type="button" onClick={openAssign} className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700">
            Assign permission to role
          </button>
        )}
      </div>
      {error && <div className="mb-4 rounded-lg bg-red-50 px-4 py-2 text-sm text-red-700">{error}</div>}
      {loading ? (
        <p className="text-slate-500">Loading…</p>
      ) : (
        <div className="overflow-hidden rounded-lg border border-slate-200 bg-white">
          <table className="w-full text-left text-sm">
            <thead className="border-b border-slate-200 bg-slate-50">
              <tr>
                <th className="px-4 py-3 font-medium text-slate-600">Role</th>
                <th className="px-4 py-3 font-medium text-slate-600">Permission</th>
                <th className="px-4 py-3 font-medium text-slate-600">Menu</th>
                <th className="px-4 py-3 font-medium text-slate-600">Actions</th>
              </tr>
            </thead>
            <tbody>
              {list.map((rp) => (
                <tr key={rp._id} className="border-b border-slate-100">
                  <td className="px-4 py-3">{roleName(rp)}</td>
                  <td className="px-4 py-3">{permName(rp)}</td>
                  <td className="px-4 py-3 text-slate-600">{permMenu(rp)}</td>
                  <td className="px-4 py-3">
                    <button type="button" onClick={() => handleRemove(rp)} className="text-red-600 hover:underline">Remove</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {modal && (
        <div className="fixed inset-0 z-10 flex items-center justify-center bg-black/40" onClick={() => setModal(false)}>
          <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-lg" onClick={(e) => e.stopPropagation()}>
            <h2 className="mb-4 text-lg font-semibold">Assign permission to role</h2>
            <form onSubmit={handleAssign} className="flex flex-col gap-4">
              <div>
                <label className="mb-1 block text-sm font-medium text-slate-600">Role</label>
                <select value={selectedRoleId} onChange={(e) => setSelectedRoleId(e.target.value)} className="w-full rounded-lg border border-slate-300 px-3 py-2">
                  {roles.map((r) => (
                    <option key={r._id} value={r._id}>{r.name}</option>
                  ))}
                </select>
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium text-slate-600">Permission</label>
                <select value={selectedPermissionId} onChange={(e) => setSelectedPermissionId(e.target.value)} className="w-full rounded-lg border border-slate-300 px-3 py-2">
                  {permissions.map((p) => (
                    <option key={p._id} value={p._id}>
                      {p.name} {typeof p.menuId === "object" && p.menuId && "path" in p.menuId ? `(${(p.menuId as { path: string }).path})` : ""}
                    </option>
                  ))}
                </select>
              </div>
              {alreadyAssigned && <p className="text-sm text-amber-700">This role already has this permission.</p>}
              <div className="flex gap-2">
                <button type="button" onClick={() => setModal(false)} className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium">Cancel</button>
                <button type="submit" disabled={submitLoading || alreadyAssigned} className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50">
                  {submitLoading ? "Assigning…" : "Assign"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
