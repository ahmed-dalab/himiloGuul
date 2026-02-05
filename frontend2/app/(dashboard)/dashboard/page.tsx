"use client";

import { useEffect, useState } from "react";
import { useAuth } from "@/lib/auth-context";
import { adminApi, type Activity } from "@/lib/api";
import { Users, Store, Handshake, Activity as ActivityIcon, Loader2 } from "lucide-react";

function formatDate(s?: string) {
  if (!s) return "—";
  try {
    return new Date(s).toLocaleString(undefined, {
      dateStyle: "short",
      timeStyle: "short",
    });
  } catch {
    return s;
  }
}

export default function DashboardPage() {
  const { user } = useAuth();
  const isAdmin = user?.role === "admin";
  const [stats, setStats] = useState<{
    totalUsers: number;
    totalActiveBusinesses: number;
    dealsClosed: number;
  } | null>(null);
  const [activities, setActivities] = useState<Activity[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    if (!isAdmin) return;
    setLoading(true);
    setError("");
    Promise.all([
      adminApi.dashboardStats(),
      adminApi.activities({ limit: 15 }),
    ])
      .then(([statsRes, activitiesRes]) => {
        setStats(statsRes.data);
        setActivities(activitiesRes.data ?? []);
      })
      .catch((e) => setError(e instanceof Error ? e.message : "Failed to load dashboard"))
      .finally(() => setLoading(false));
  }, [isAdmin]);

  return (
    <div>
      <h1 className="mb-2 text-2xl font-semibold text-slate-800">Dashboard</h1>
      <p className="mb-6 text-slate-600">
        Welcome, {user?.name ?? user?.email}.{" "}
        {isAdmin
          ? "Overview of platform stats and recent activity."
          : `You are logged in as ${user?.role ?? "user"}. Seller and buyer features are coming soon.`}
      </p>

      {isAdmin && (
        <>
          {error && (
            <div className="mb-6 rounded-lg bg-amber-50 px-4 py-3 text-sm text-amber-800">
              {error}
            </div>
          )}
          {loading ? (
            <div className="flex items-center gap-2 text-slate-500">
              <Loader2 className="h-5 w-5 animate-spin" aria-hidden />
              Loading…
            </div>
          ) : stats ? (
            <div className="mb-8 grid gap-4 sm:grid-cols-3">
              <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
                <div className="flex items-center gap-3">
                  <div className="rounded-lg bg-blue-50 p-2">
                    <Users className="h-6 w-6 text-blue-600" aria-hidden />
                  </div>
                  <div>
                    <p className="text-sm font-medium text-slate-500">Total users</p>
                    <p className="text-2xl font-semibold text-slate-800">{stats.totalUsers}</p>
                  </div>
                </div>
              </div>
              <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
                <div className="flex items-center gap-3">
                  <div className="rounded-lg bg-emerald-50 p-2">
                    <Store className="h-6 w-6 text-emerald-600" aria-hidden />
                  </div>
                  <div>
                    <p className="text-sm font-medium text-slate-500">Active listings</p>
                    <p className="text-2xl font-semibold text-slate-800">{stats.totalActiveBusinesses}</p>
                  </div>
                </div>
              </div>
              <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
                <div className="flex items-center gap-3">
                  <div className="rounded-lg bg-violet-50 p-2">
                    <Handshake className="h-6 w-6 text-violet-600" aria-hidden />
                  </div>
                  <div>
                    <p className="text-sm font-medium text-slate-500">Deals closed</p>
                    <p className="text-2xl font-semibold text-slate-800">{stats.dealsClosed}</p>
                  </div>
                </div>
              </div>
            </div>
          ) : null}

          {stats && (
            <div>
              <h2 className="mb-3 flex items-center gap-2 text-lg font-semibold text-slate-800">
                <ActivityIcon className="h-5 w-5 text-slate-500" aria-hidden />
                Recent activity
              </h2>
              {activities.length === 0 ? (
                <p className="rounded-xl border border-slate-200 bg-white px-4 py-6 text-center text-slate-500">
                  No recent activity.
                </p>
              ) : (
                <ul className="rounded-xl border border-slate-200 bg-white shadow-sm overflow-hidden divide-y divide-slate-100">
                  {activities.map((a) => (
                    <li key={a._id} className="px-4 py-3 flex flex-wrap items-center gap-2 text-sm">
                      <span className="font-medium text-slate-700">{a.type}</span>
                      <span className="text-slate-600">{a.description}</span>
                      <span className="ml-auto text-slate-400">{formatDate(a.createdAt)}</span>
                    </li>
                  ))}
                </ul>
              )}
            </div>
          )}
        </>
      )}
    </div>
  );
}
