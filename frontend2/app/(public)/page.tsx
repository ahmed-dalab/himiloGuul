"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { useAuth } from "@/lib/auth-context";
import { businessesApi, type Business } from "@/lib/api";
import { Store, MapPin, Eye, Loader2 } from "lucide-react";

function formatPrice(n?: number) {
  if (n == null) return "—";
  return new Intl.NumberFormat("en-US", { style: "currency", currency: "USD", maximumFractionDigits: 0 }).format(n);
}

function formatCategory(c?: string) {
  if (!c) return "—";
  return c.replace(/-/g, " ").replace(/\b\w/g, (ch) => ch.toUpperCase());
}

export default function PublicHomePage() {
  const router = useRouter();
  const { token, ready } = useAuth();
  const [businesses, setBusinesses] = useState<Business[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    if (token && ready) {
      router.replace("/dashboard");
      return;
    }
  }, [token, ready, router]);

  useEffect(() => {
    setLoading(true);
    setError("");
    businessesApi
      .list({ limit: 24 })
      .then((res) => setBusinesses(res.data))
      .catch((e) => setError(e instanceof Error ? e.message : "Failed to load businesses"))
      .finally(() => setLoading(false));
  }, []);

  if (token !== null && ready) return null; // redirecting to dashboard

  return (
    <div className="mx-auto max-w-6xl px-4 py-8">
      <div className="mb-8">
        <h1 className="text-2xl font-semibold text-slate-800 sm:text-3xl">
          Businesses for sale
        </h1>
        <p className="mt-1 text-slate-600">
          Browse approved listings. Sign up as a buyer to get started.
        </p>
      </div>

      {error && (
        <div className="mb-6 rounded-lg bg-amber-50 px-4 py-3 text-sm text-amber-800">
          {error}
        </div>
      )}

      {loading ? (
        <div className="flex items-center justify-center py-16">
          <Loader2 className="h-8 w-8 animate-spin text-slate-400" aria-hidden />
        </div>
      ) : businesses.length === 0 ? (
        <div className="rounded-xl border border-slate-200 bg-white py-16 text-center">
          <Store className="mx-auto h-12 w-12 text-slate-300" aria-hidden />
          <p className="mt-4 text-slate-600">No businesses listed yet.</p>
          <p className="mt-1 text-sm text-slate-500">Check back later or log in to add listings.</p>
        </div>
      ) : (
        <ul className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {businesses.map((b) => (
            <li
              key={b._id}
              className="flex flex-col overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm transition-shadow hover:shadow-md"
            >
              {b.images?.[0]?.url ? (
                <img
                  src={b.images[0].url}
                  alt=""
                  className="h-44 w-full object-cover"
                />
              ) : (
                <div className="flex h-44 w-full items-center justify-center bg-slate-100">
                  <Store className="h-12 w-12 text-slate-300" aria-hidden />
                </div>
              )}
              <div className="flex flex-1 flex-col p-4">
                <h2 className="font-semibold text-slate-800 line-clamp-1">{b.name}</h2>
                {b.category && (
                  <p className="mt-1 text-sm text-slate-500">{formatCategory(b.category)}</p>
                )}
                {b.location && (
                  <p className="mt-1 flex items-center gap-1 text-sm text-slate-600">
                    <MapPin className="h-4 w-4 shrink-0 text-slate-400" aria-hidden />
                    <span className="line-clamp-1">{b.location}</span>
                  </p>
                )}
                {b.askingPrice != null && (
                  <p className="mt-2 text-sm font-medium text-slate-700">{formatPrice(b.askingPrice)}</p>
                )}
                <div className="mt-auto pt-4">
                  <Link
                    href={`/business/${b._id}`}
                    className="inline-flex items-center gap-2 rounded-lg bg-blue-600 px-3 py-2 text-sm font-medium text-white hover:bg-blue-700"
                  >
                    <Eye className="h-4 w-4" aria-hidden />
                    View
                  </Link>
                </div>
              </div>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
