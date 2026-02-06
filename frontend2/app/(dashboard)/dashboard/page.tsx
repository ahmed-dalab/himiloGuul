"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useAuth } from "@/lib/auth-context";
import { adminApi, businessesApi, contactsApi, type Activity, type Business, type Contact } from "@/lib/api";
import { Users, Store, Activity as ActivityIcon, Loader2, MessageSquare, ChevronRight, Briefcase, Compass, Send } from "lucide-react";

function formatPrice(n?: number) {
  if (n == null) return "—";
  return new Intl.NumberFormat("en-US", { style: "currency", currency: "USD", maximumFractionDigits: 0 }).format(n);
}

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
  const isSeller = user?.role === "seller";
  const isBuyer = user?.role === "buyer";

  // Admin state
  const [stats, setStats] = useState<{
    totalUsers: number;
    totalActiveBusinesses: number;
  } | null>(null);
  const [activities, setActivities] = useState<Activity[]>([]);
  const [adminLoading, setAdminLoading] = useState(false);
  const [adminError, setAdminError] = useState("");

  // Seller state
  const [myBusinessesCount, setMyBusinessesCount] = useState<number | null>(null);
  const [inquiriesCount, setInquiriesCount] = useState<number | null>(null);
  const [sellerLoading, setSellerLoading] = useState(false);
  const [sellerError, setSellerError] = useState("");

  // Buyer state
  const [myInquiriesCount, setMyInquiriesCount] = useState<number | null>(null);
  const [activeBusinessesCount, setActiveBusinessesCount] = useState<number | null>(null);
  const [activeBusinesses, setActiveBusinesses] = useState<Business[]>([]);
  const [recentInquiries, setRecentInquiries] = useState<Contact[]>([]);
  const [buyerLoading, setBuyerLoading] = useState(false);
  const [buyerError, setBuyerError] = useState("");

  useEffect(() => {
    if (!isAdmin) return;
    setAdminLoading(true);
    setAdminError("");
    Promise.all([
      adminApi.dashboardStats(),
      adminApi.activities({ limit: 15 }),
    ])
      .then(([statsRes, activitiesRes]) => {
        setStats(statsRes.data);
        setActivities(activitiesRes.data ?? []);
      })
      .catch((e) => setAdminError(e instanceof Error ? e.message : "Failed to load dashboard"))
      .finally(() => setAdminLoading(false));
  }, [isAdmin]);

  useEffect(() => {
    if (!isSeller) return;
    setSellerLoading(true);
    setSellerError("");
    Promise.all([
      businessesApi.myList({ page: 1, limit: 1 }),
      contactsApi.myList({ page: 1, limit: 1, role: "seller" }),
    ])
      .then(([businessesRes, contactsRes]) => {
        setMyBusinessesCount(businessesRes.pagination?.total ?? 0);
        setInquiriesCount(contactsRes.pagination?.total ?? 0);
      })
      .catch((e) => setSellerError(e instanceof Error ? e.message : "Failed to load"))
      .finally(() => setSellerLoading(false));
  }, [isSeller]);

  useEffect(() => {
    if (!isBuyer) return;
    setBuyerLoading(true);
    setBuyerError("");
    Promise.all([
      contactsApi.myList({ page: 1, limit: 1, role: "buyer" }),
      businessesApi.list({ limit: 6 }),
      contactsApi.myList({ page: 1, limit: 5, role: "buyer", sortBy: "createdAt", sortOrder: "desc" }),
    ])
      .then(([inquiriesRes, businessesRes, recentRes]) => {
        setMyInquiriesCount(inquiriesRes.pagination?.total ?? 0);
        setActiveBusinessesCount(businessesRes.pagination?.total ?? 0);
        setActiveBusinesses(businessesRes.data ?? []);
        setRecentInquiries(recentRes.data ?? []);
      })
      .catch((e) => setBuyerError(e instanceof Error ? e.message : "Failed to load"))
      .finally(() => setBuyerLoading(false));
  }, [isBuyer]);

  return (
    <div>
      <h1 className="mb-2 text-2xl font-semibold text-slate-800">Dashboard</h1>
      <p className="mb-6 text-slate-600">
        Welcome, {user?.name ?? user?.email}.{" "}
        {isAdmin && "Overview of platform stats and recent activity."}
        {isSeller && "Manage your listings and buyer inquiries."}
        {isBuyer && "Browse active listings and track inquiries you’ve sent to sellers."}
        {!isAdmin && !isSeller && !isBuyer && `You are logged in as ${user?.role ?? "user"}.`}
      </p>

      {/* Buyer dashboard */}
      {isBuyer && (
        <>
          {buyerError && (
            <div className="mb-6 rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
              {buyerError}
            </div>
          )}
          {buyerLoading ? (
            <div className="flex items-center gap-2 py-12 text-slate-500">
              <Loader2 className="h-6 w-6 animate-spin" aria-hidden />
              Loading…
            </div>
          ) : (
            <div className="space-y-8">
              <div className="grid gap-4 sm:grid-cols-2">
                <Link
                  href="/"
                  className="group flex items-center gap-4 rounded-xl border border-slate-200 bg-white p-6 shadow-sm transition-shadow hover:border-slate-300 hover:shadow-md"
                >
                  <div className="flex h-14 w-14 shrink-0 items-center justify-center rounded-xl bg-blue-50">
                    <Compass className="h-7 w-7 text-blue-600" aria-hidden />
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="text-sm font-medium text-slate-500">Active listings</p>
                    <p className="text-2xl font-semibold text-slate-800">
                      {activeBusinessesCount ?? "—"}
                    </p>
                    <p className="mt-0.5 text-xs text-slate-500">Businesses for sale</p>
                  </div>
                  <ChevronRight className="h-5 w-5 shrink-0 text-slate-400 group-hover:text-slate-600" aria-hidden />
                </Link>
                <Link
                  href="/dashboard/my-inquiries"
                  className="group flex items-center gap-4 rounded-xl border border-slate-200 bg-white p-6 shadow-sm transition-shadow hover:border-slate-300 hover:shadow-md"
                >
                  <div className="flex h-14 w-14 shrink-0 items-center justify-center rounded-xl bg-violet-50">
                    <Send className="h-7 w-7 text-violet-600" aria-hidden />
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="text-sm font-medium text-slate-500">Inquiries sent</p>
                    <p className="text-2xl font-semibold text-slate-800">
                      {myInquiriesCount ?? "—"}
                    </p>
                    <p className="mt-0.5 text-xs text-slate-500">Messages to sellers</p>
                  </div>
                  <ChevronRight className="h-5 w-5 shrink-0 text-slate-400 group-hover:text-slate-600" aria-hidden />
                </Link>
              </div>

              <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
                <div className="mb-4 flex items-center justify-between">
                  <h2 className="text-lg font-semibold text-slate-800">Active listings</h2>
                  <Link
                    href="/"
                    className="text-sm font-medium text-blue-600 hover:underline"
                  >
                    View all
                  </Link>
                </div>
                {activeBusinesses.length === 0 ? (
                  <p className="py-6 text-center text-slate-500">No active listings right now.</p>
                ) : (
                  <ul className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
                    {activeBusinesses.map((b) => (
                      <li
                        key={b._id}
                        className="overflow-hidden rounded-lg border border-slate-100 transition-shadow hover:shadow-md"
                      >
                        <Link href={`/business/${b._id}`} className="block">
                          {b.images?.[0]?.url ? (
                            <img
                              src={b.images[0].url}
                              alt=""
                              className="h-36 w-full object-cover"
                            />
                          ) : (
                            <div className="flex h-36 items-center justify-center bg-slate-100">
                              <Store className="h-10 w-10 text-slate-300" aria-hidden />
                            </div>
                          )}
                          <div className="p-3">
                            <p className="font-medium text-slate-800 line-clamp-1">{b.name}</p>
                            {b.location && (
                              <p className="mt-0.5 text-xs text-slate-500 line-clamp-1">{b.location}</p>
                            )}
                            <p className="mt-1 text-sm font-medium text-slate-700">
                              {formatPrice(b.askingPrice)}
                            </p>
                          </div>
                        </Link>
                      </li>
                    ))}
                  </ul>
                )}
              </div>

              <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
                <div className="mb-4 flex items-center justify-between">
                  <h2 className="text-lg font-semibold text-slate-800">Recent inquiries</h2>
                  {myInquiriesCount !== null && myInquiriesCount > 0 && (
                    <Link
                      href="/dashboard/my-inquiries"
                      className="text-sm font-medium text-blue-600 hover:underline"
                    >
                      View all
                    </Link>
                  )}
                </div>
                {recentInquiries.length === 0 ? (
                  <p className="py-6 text-center text-slate-500">
                    You haven’t sent any inquiries yet. Browse businesses and contact sellers.
                  </p>
                ) : (
                  <ul className="divide-y divide-slate-100">
                    {recentInquiries.map((c) => (
                      <li key={c._id} className="flex flex-wrap items-center gap-2 py-3 first:pt-0">
                        <span className="font-medium text-slate-700">
                          {c.businessRef && typeof c.businessRef === "object" ? c.businessRef.name : "—"}
                        </span>
                        <span className="text-slate-500">·</span>
                        <span className="truncate text-sm text-slate-600 max-w-[12rem]" title={c.message}>
                          {c.message}
                        </span>
                        <span
                          className={`ml-auto rounded-full px-2 py-0.5 text-xs font-medium ${
                            c.status === "closed"
                              ? "bg-slate-100 text-slate-700"
                              : c.status === "responded"
                                ? "bg-blue-100 text-blue-800"
                                : "bg-amber-100 text-amber-800"
                          }`}
                        >
                          {c.status ?? "pending"}
                        </span>
                        {c.businessRef && typeof c.businessRef === "object" && c.businessRef._id && (
                          <Link
                            href={`/business/${c.businessRef._id}`}
                            className="text-sm text-blue-600 hover:underline"
                          >
                            View
                          </Link>
                        )}
                      </li>
                    ))}
                  </ul>
                )}
              </div>

              <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
                <h2 className="mb-3 text-lg font-semibold text-slate-800">Quick actions</h2>
                <div className="flex flex-wrap gap-3">
                  <Link
                    href="/"
                    className="inline-flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700"
                  >
                    <Compass className="h-4 w-4" aria-hidden />
                    Browse businesses
                  </Link>
                  <Link
                    href="/dashboard/my-inquiries"
                    className="inline-flex items-center gap-2 rounded-lg border border-slate-200 bg-white px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
                  >
                    <Send className="h-4 w-4" aria-hidden />
                    My inquiries
                  </Link>
                </div>
              </div>
            </div>
          )}
        </>
      )}

      {/* Seller dashboard */}
      {isSeller && (
        <>
          {sellerError && (
            <div className="mb-6 rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
              {sellerError}
            </div>
          )}
          {sellerLoading ? (
            <div className="flex items-center gap-2 py-12 text-slate-500">
              <Loader2 className="h-6 w-6 animate-spin" aria-hidden />
              Loading…
            </div>
          ) : (
            <div className="space-y-8">
              <div className="grid gap-4 sm:grid-cols-2">
                <Link
                  href="/dashboard/my-businesses"
                  className="group flex items-center gap-4 rounded-xl border border-slate-200 bg-white p-6 shadow-sm transition-shadow hover:border-slate-300 hover:shadow-md"
                >
                  <div className="flex h-14 w-14 shrink-0 items-center justify-center rounded-xl bg-emerald-50">
                    <Briefcase className="h-7 w-7 text-emerald-600" aria-hidden />
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="text-sm font-medium text-slate-500">My businesses</p>
                    <p className="text-2xl font-semibold text-slate-800">
                      {myBusinessesCount ?? "—"}
                    </p>
                    <p className="mt-0.5 text-xs text-slate-500">Listings you’ve added</p>
                  </div>
                  <ChevronRight className="h-5 w-5 shrink-0 text-slate-400 group-hover:text-slate-600" aria-hidden />
                </Link>
                <Link
                  href="/dashboard/inquiries"
                  className="group flex items-center gap-4 rounded-xl border border-slate-200 bg-white p-6 shadow-sm transition-shadow hover:border-slate-300 hover:shadow-md"
                >
                  <div className="flex h-14 w-14 shrink-0 items-center justify-center rounded-xl bg-violet-50">
                    <MessageSquare className="h-7 w-7 text-violet-600" aria-hidden />
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="text-sm font-medium text-slate-500">Inquiries</p>
                    <p className="text-2xl font-semibold text-slate-800">
                      {inquiriesCount ?? "—"}
                    </p>
                    <p className="mt-0.5 text-xs text-slate-500">Messages from buyers</p>
                  </div>
                  <ChevronRight className="h-5 w-5 shrink-0 text-slate-400 group-hover:text-slate-600" aria-hidden />
                </Link>
              </div>
              <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
                <h2 className="mb-3 text-lg font-semibold text-slate-800">Quick actions</h2>
                <div className="flex flex-wrap gap-3">
                  <Link
                    href="/dashboard/my-businesses"
                    className="inline-flex items-center gap-2 rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-700"
                  >
                    <Briefcase className="h-4 w-4" aria-hidden />
                    My businesses
                  </Link>
                  <Link
                    href="/dashboard/inquiries"
                    className="inline-flex items-center gap-2 rounded-lg border border-slate-200 bg-white px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
                  >
                    <MessageSquare className="h-4 w-4" aria-hidden />
                    View inquiries
                  </Link>
                </div>
              </div>
            </div>
          )}
        </>
      )}

      {/* Admin dashboard */}
      {isAdmin && (
        <>
          {adminError && (
            <div className="mb-6 rounded-lg bg-amber-50 px-4 py-3 text-sm text-amber-800">
              {adminError}
            </div>
          )}
          {adminLoading ? (
            <div className="flex items-center gap-2 text-slate-500">
              <Loader2 className="h-5 w-5 animate-spin" aria-hidden />
              Loading…
            </div>
          ) : stats ? (
            <div className="mb-8 grid gap-4 sm:grid-cols-2">
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
                <ul className="divide-y divide-slate-100 overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
                  {activities.map((a) => (
                    <li key={a._id} className="flex flex-wrap items-center gap-2 px-4 py-3 text-sm">
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
