"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import Link from "next/link";
import { useAuth } from "@/lib/auth-context";
import { businessesApi, contactsApi, type Business } from "@/lib/api";
import { Store, MapPin, Mail, Phone, Globe, ArrowLeft, Loader2, MessageSquare, LogIn, UserPlus } from "lucide-react";

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
  const id = params.id as string;
  const { user, token } = useAuth();
  const [business, setBusiness] = useState<Business | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [contactForm, setContactForm] = useState({ name: "", email: "", phone: "", message: "" });
  const [contactSubmitting, setContactSubmitting] = useState(false);
  const [contactSuccess, setContactSuccess] = useState(false);
  const [contactError, setContactError] = useState("");

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

  useEffect(() => {
    if (user) {
      setContactForm((f) => ({
        ...f,
        name: user.name ?? f.name,
        email: user.email ?? f.email,
      }));
    }
  }, [user?.name, user?.email]);

  const handleContactSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!business?.owner || !token) return;
    const ownerId = typeof business.owner === "object" ? business.owner._id : business.owner;
    if (!ownerId) return;
    setContactSubmitting(true);
    setContactError("");
    try {
      await contactsApi.create({
        sellerRef: ownerId,
        businessRef: business._id,
        name: contactForm.name.trim(),
        email: contactForm.email.trim(),
        phone: contactForm.phone.trim() || undefined,
        message: contactForm.message.trim(),
      });
      setContactSuccess(true);
      setContactForm((f) => ({ ...f, message: "" }));
    } catch (err) {
      setContactError(err instanceof Error ? err.message : "Failed to send inquiry");
    } finally {
      setContactSubmitting(false);
    }
  };

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

          {/* Contact / Inquiry form */}
          <div className="mt-10 border-t border-slate-200 pt-8">
            <h2 className="mb-4 flex items-center gap-2 text-lg font-semibold text-slate-800">
              <MessageSquare className="h-5 w-5 text-slate-500" aria-hidden />
              Send an inquiry
            </h2>
            {token && business?.owner && typeof business.owner === "object" && user?._id === business.owner._id ? (
              <p className="rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-slate-600">
                This is your listing. Inquiries from buyers will appear in your{" "}
                <Link href="/dashboard/inquiries" className="font-medium text-blue-600 hover:underline">
                  Inquiries
                </Link>{" "}
                dashboard.
              </p>
            ) : !token ? (
              <div className="rounded-xl border border-slate-200 bg-slate-50 p-6 text-center">
                <p className="text-slate-700">Please log in or register to send a message to the seller.</p>
                <div className="mt-4 flex flex-wrap items-center justify-center gap-3">
                  <Link
                    href={`/login?returnTo=${encodeURIComponent(`/business/${id}`)}`}
                    className="inline-flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700"
                  >
                    <LogIn className="h-4 w-4" aria-hidden />
                    Log in
                  </Link>
                  <Link
                    href={`/register?returnTo=${encodeURIComponent(`/business/${id}`)}`}
                    className="inline-flex items-center gap-2 rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
                  >
                    <UserPlus className="h-4 w-4" aria-hidden />
                    Register
                  </Link>
                </div>
              </div>
            ) : contactSuccess ? (
              <div className="rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-emerald-800">
                Your message has been sent. The seller will see it in their Inquiries.
              </div>
            ) : (
              <form onSubmit={handleContactSubmit} className="space-y-4">
                {contactError && (
                  <div className="rounded-lg bg-amber-50 px-4 py-3 text-sm text-amber-800">
                    {contactError}
                  </div>
                )}
                <div className="grid gap-4 sm:grid-cols-2">
                  <div>
                    <label htmlFor="contact-name" className="mb-1 block text-sm font-medium text-slate-600">
                      Your name *
                    </label>
                    <input
                      id="contact-name"
                      type="text"
                      required
                      value={contactForm.name}
                      onChange={(e) => setContactForm((f) => ({ ...f, name: e.target.value }))}
                      className="w-full rounded-lg border border-slate-300 px-3 py-2 text-slate-800 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                      placeholder="Your name"
                    />
                  </div>
                  <div>
                    <label htmlFor="contact-email" className="mb-1 block text-sm font-medium text-slate-600">
                      Email *
                    </label>
                    <input
                      id="contact-email"
                      type="email"
                      required
                      value={contactForm.email}
                      onChange={(e) => setContactForm((f) => ({ ...f, email: e.target.value }))}
                      className="w-full rounded-lg border border-slate-300 px-3 py-2 text-slate-800 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                      placeholder="you@example.com"
                    />
                  </div>
                </div>
                <div>
                  <label htmlFor="contact-phone" className="mb-1 block text-sm font-medium text-slate-600">
                    Phone (optional)
                  </label>
                  <input
                    id="contact-phone"
                    type="tel"
                    value={contactForm.phone}
                    onChange={(e) => setContactForm((f) => ({ ...f, phone: e.target.value }))}
                    className="w-full rounded-lg border border-slate-300 px-3 py-2 text-slate-800 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                    placeholder="+1 234 567 8900"
                  />
                </div>
                <div>
                  <label htmlFor="contact-message" className="mb-1 block text-sm font-medium text-slate-600">
                    Message *
                  </label>
                  <textarea
                    id="contact-message"
                    required
                    rows={4}
                    value={contactForm.message}
                    onChange={(e) => setContactForm((f) => ({ ...f, message: e.target.value }))}
                    className="w-full rounded-lg border border-slate-300 px-3 py-2 text-slate-800 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                    placeholder="Ask about this business, request more details, or express your interest…"
                  />
                </div>
                <button
                  type="submit"
                  disabled={contactSubmitting}
                  className="inline-flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2.5 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50"
                >
                  {contactSubmitting ? (
                    <>
                      <Loader2 className="h-4 w-4 animate-spin" aria-hidden />
                      Sending…
                    </>
                  ) : (
                    <>
                      <MessageSquare className="h-4 w-4" aria-hidden />
                      Send inquiry
                    </>
                  )}
                </button>
              </form>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
