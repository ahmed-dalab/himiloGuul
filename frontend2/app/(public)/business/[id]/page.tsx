"use client";

import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import Link from "next/link";
import { businessesApi, type Business } from "@/lib/api";
import { Store, MapPin, Mail, Phone, Globe, ArrowLeft, Loader2 } from "lucide-react";

function formatPrice(n?: number) {
  if (n == null) return "—";
  return new Intl.NumberFormat("en-US", { style: "currency", currency: "USD", maximumFractionDigits: 0 }).format(n);
}

function formatCategory(c?: string) {
  if (!c) return "—";
  return c.replace(/-/g, " ").replace(/\b\w/g, (ch) => ch.toUpperCase());
}

export default function BusinessDetailPage() {
  const params = useParams();
  const router = useRouter();
  const id = params.id as string;
  const [business, setBusiness] = useState<Business | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    if (!id) return;
    setLoading(true);
    setError("");
    businessesApi
      .get(id)
      .then((res) => setBusiness(res.data))
      .catch((e) => setError(e instanceof Error ? e.message : "Failed to load"))
      .finally(() => setLoading(false));
  }, [id]);

  if (loading) {
    return (
      <div className="flex min-h-[40vh] items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-slate-400" aria-hidden />
      </div>
    );
  }

  if (error || !business) {
    return (
      <div className="mx-auto max-w-2xl px-4 py-12 text-center">
        <p className="text-slate-600">{error || "Business not found."}</p>
        <Link
          href="/"
          className="mt-4 inline-flex items-center gap-2 text-blue-600 hover:underline"
        >
          <ArrowLeft className="h-4 w-4" aria-hidden />
          Back to listings
        </Link>
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-4xl px-4 py-8">
      <Link
        href="/"
        className="mb-6 inline-flex items-center gap-2 text-sm font-medium text-slate-600 hover:text-slate-800"
      >
        <ArrowLeft className="h-4 w-4" aria-hidden />
        Back to businesses
      </Link>

      <div className="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
        {business.images && business.images.length > 0 ? (
          <div className="flex gap-1 overflow-x-auto p-2">
            {business.images.map((img, i) => (
              <img
                key={img.publicId || i}
                src={img.url}
                alt=""
                className="h-64 w-auto shrink-0 rounded-lg object-cover"
              />
            ))}
          </div>
        ) : (
          <div className="flex h-64 items-center justify-center bg-slate-100">
            <Store className="h-16 w-16 text-slate-300" aria-hidden />
          </div>
        )}

        <div className="p-6 sm:p-8">
          <div className="flex flex-wrap items-start justify-between gap-4">
            <div>
              <h1 className="text-2xl font-semibold text-slate-800">{business.name}</h1>
              {business.category && (
                <p className="mt-1 text-slate-600">{formatCategory(business.category)}</p>
              )}
            </div>
            {business.askingPrice != null && (
              <p className="text-xl font-semibold text-slate-800">{formatPrice(business.askingPrice)}</p>
            )}
          </div>

          {business.description && (
            <div className="mt-6">
              <h2 className="text-sm font-medium text-slate-500">Description</h2>
              <p className="mt-2 whitespace-pre-wrap text-slate-700">{business.description}</p>
            </div>
          )}

          <div className="mt-8 grid gap-4 sm:grid-cols-2">
            {business.location && (
              <div className="flex items-start gap-3">
                <MapPin className="h-5 w-5 shrink-0 text-slate-400" aria-hidden />
                <div>
                  <p className="text-xs font-medium uppercase tracking-wide text-slate-500">Location</p>
                  <p className="text-slate-700">{business.location}</p>
                </div>
              </div>
            )}
            {business.address && (
              <div className="flex items-start gap-3">
                <MapPin className="h-5 w-5 shrink-0 text-slate-400" aria-hidden />
                <div>
                  <p className="text-xs font-medium uppercase tracking-wide text-slate-500">Address</p>
                  <p className="text-slate-700">{business.address}</p>
                </div>
              </div>
            )}
            {business.email && (
              <div className="flex items-start gap-3">
                <Mail className="h-5 w-5 shrink-0 text-slate-400" aria-hidden />
                <div>
                  <p className="text-xs font-medium uppercase tracking-wide text-slate-500">Email</p>
                  <a href={`mailto:${business.email}`} className="text-slate-700 hover:underline">{business.email}</a>
                </div>
              </div>
            )}
            {business.phone && (
              <div className="flex items-start gap-3">
                <Phone className="h-5 w-5 shrink-0 text-slate-400" aria-hidden />
                <div>
                  <p className="text-xs font-medium uppercase tracking-wide text-slate-500">Phone</p>
                  <a href={`tel:${business.phone}`} className="text-slate-700 hover:underline">{business.phone}</a>
                </div>
              </div>
            )}
            {business.website && (
              <div className="flex items-start gap-3">
                <Globe className="h-5 w-5 shrink-0 text-slate-400" aria-hidden />
                <div>
                  <p className="text-xs font-medium uppercase tracking-wide text-slate-500">Website</p>
                  <a href={business.website} target="_blank" rel="noopener noreferrer" className="text-slate-700 hover:underline">{business.website}</a>
                </div>
              </div>
            )}
          </div>

          {business.annualRevenue != null && (
            <div className="mt-6">
              <p className="text-xs font-medium uppercase tracking-wide text-slate-500">Annual revenue</p>
              <p className="mt-1 text-slate-700">{formatPrice(business.annualRevenue)}</p>
            </div>
          )}

          {business.owner && (
            <div className="mt-8 border-t border-slate-100 pt-6">
              <p className="text-xs font-medium uppercase tracking-wide text-slate-500">Listed by</p>
              <p className="mt-1 text-slate-700">
                {typeof business.owner === "object" ? business.owner.name : "—"}
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
