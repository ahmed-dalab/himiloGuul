"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useAuth } from "@/lib/auth-context";
import { businessesApi, type Business } from "@/lib/api";
import {
  Store,
  MapPin,
  Plus,
  Pencil,
  Trash2,
  Eye,
  CheckCircle,
  XCircle,
  Loader2,
  Tag,
  ImagePlus,
  ChevronRight,
  ChevronLeft,
  X,
} from "lucide-react";

const STEPS = [
  { id: 1, title: "Basic info" },
  { id: 2, title: "Details" },
  { id: 3, title: "Images (optional)" },
];
const MAX_IMAGES = 10;
const MAX_FILE_SIZE_MB = 5;

const CATEGORIES = [
  "restaurant",
  "retail",
  "service",
  "technology",
  "healthcare",
  "education",
  "real-estate",
  "hospitality",
  "other",
];

function formatPrice(n?: number) {
  if (n == null) return "—";
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
    maximumFractionDigits: 0,
  }).format(n);
}

function formatCategory(c?: string) {
  if (!c) return "—";
  return c.replace(/-/g, " ").replace(/\b\w/g, (ch) => ch.toUpperCase());
}

type FormState = Partial<
  Pick<
    Business,
    "name" | "description" | "category" | "location" | "askingPrice" | "annualRevenue" | "phone" | "email" | "website" | "address"
  >
>;

const emptyForm: FormState = {
  name: "",
  description: "",
  category: "",
  location: "",
  askingPrice: undefined,
  annualRevenue: undefined,
  phone: "",
  email: "",
  website: "",
  address: "",
};

export default function MyBusinessesPage() {
  const { user, ready } = useAuth();
  const isSeller = user?.role === "seller";
  const [list, setList] = useState<Business[]>([]);
  const [pagination, setPagination] = useState({ page: 1, limit: 10, total: 0, pages: 0 });
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [modal, setModal] = useState<"create" | "edit" | null>(null);
  const [editing, setEditing] = useState<Business | null>(null);
  const [form, setForm] = useState<FormState>(emptyForm);
  const [step, setStep] = useState(1);
  const [selectedFiles, setSelectedFiles] = useState<File[]>([]);
  const [filePreviews, setFilePreviews] = useState<string[]>([]);
  const [submitLoading, setSubmitLoading] = useState(false);
  const [actionId, setActionId] = useState<string | null>(null);

  const load = () => {
    setLoading(true);
    setError("");
    businessesApi
      .myList({ page, limit: 10 })
      .then((res) => {
        setList(res.data);
        setPagination(res.pagination);
      })
      .catch((e) => setError(e instanceof Error ? e.message : "Failed to load"))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    if (!isSeller) return;
    load();
  }, [isSeller, page]);

  const openCreate = () => {
    setEditing(null);
    setForm(emptyForm);
    setStep(1);
    setSelectedFiles([]);
    setFilePreviews([]);
    setError("");
    setModal("create");
  };

  const openEdit = (b: Business) => {
    setEditing(b);
    setForm({
      name: b.name ?? "",
      description: b.description ?? "",
      category: b.category ?? "",
      location: b.location ?? "",
      askingPrice: b.askingPrice,
      annualRevenue: b.annualRevenue,
      phone: b.phone ?? "",
      email: b.email ?? "",
      website: b.website ?? "",
      address: b.address ?? "",
    });
    setStep(1);
    setSelectedFiles([]);
    setFilePreviews([]);
    setError("");
    setModal("edit");
  };

  const closeModal = () => {
    setModal(null);
    setEditing(null);
    setForm(emptyForm);
    setStep(1);
    setSelectedFiles([]);
    filePreviews.forEach((url) => URL.revokeObjectURL(url));
    setFilePreviews([]);
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files ?? []);
    const valid: File[] = [];
    const tooBig: string[] = [];
    const notImage: string[] = [];
    for (const f of files) {
      if (!f.type.startsWith("image/")) {
        notImage.push(f.name);
        continue;
      }
      if (f.size > MAX_FILE_SIZE_MB * 1024 * 1024) {
        tooBig.push(f.name);
        continue;
      }
      valid.push(f);
    }
    const errs: string[] = [];
    if (tooBig.length) errs.push(`Max ${MAX_FILE_SIZE_MB}MB per file: ${tooBig.join(", ")}`);
    if (notImage.length) errs.push(`Images only: ${notImage.join(", ")}`);
    if (errs.length) setError(errs.join(". "));
    const combined = [...selectedFiles, ...valid].slice(0, MAX_IMAGES);
    setSelectedFiles(combined);
    filePreviews.forEach((url) => URL.revokeObjectURL(url));
    setFilePreviews(combined.map((f) => URL.createObjectURL(f)));
    e.target.value = "";
  };

  const removeFile = (index: number) => {
    setSelectedFiles((prev) => prev.filter((_, i) => i !== index));
    setFilePreviews((prev) => {
      URL.revokeObjectURL(prev[index]);
      return prev.filter((_, i) => i !== index);
    });
  };

  const buildFormData = (): FormData => {
    const fd = new FormData();
    if (form.name?.trim()) fd.append("name", form.name.trim());
    if (form.description?.trim()) fd.append("description", form.description.trim());
    if (form.category) fd.append("category", form.category);
    if (form.location?.trim()) fd.append("location", form.location.trim());
    if (form.askingPrice != null && form.askingPrice !== "") fd.append("askingPrice", String(form.askingPrice));
    if (form.annualRevenue != null && form.annualRevenue !== "") fd.append("annualRevenue", String(form.annualRevenue));
    if (form.phone?.trim()) fd.append("phone", form.phone.trim());
    if (form.email?.trim()) fd.append("email", form.email.trim());
    if (form.website?.trim()) fd.append("website", form.website.trim());
    if (form.address?.trim()) fd.append("address", form.address.trim());
    selectedFiles.forEach((file) => fd.append("images", file));
    return fd;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (step < 3) {
      if (step === 1 && !form.name?.trim()) {
        setError("Business name is required");
        return;
      }
      setError("");
      setStep((s) => s + 1);
      return;
    }
    if (!form.name?.trim()) return;
    setSubmitLoading(true);
    setError("");
    try {
      const formData = buildFormData();
      if (editing) {
        await businessesApi.updateWithFormData(editing._id, formData);
      } else {
        await businessesApi.createWithFormData(formData);
      }
      closeModal();
      load();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to save");
    } finally {
      setSubmitLoading(false);
    }
  };

  const goBack = () => {
    if (step > 1) setStep((s) => s - 1);
  };

  const handleDelete = async (b: Business) => {
    if (!confirm(`Delete "${b.name}"?`)) return;
    setActionId(b._id);
    try {
      await businessesApi.delete(b._id);
      load();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to delete");
    } finally {
      setActionId(null);
    }
  };

  const handleMarkSold = async (b: Business, isSold: boolean) => {
    setActionId(b._id);
    try {
      await businessesApi.markSold(b._id, isSold);
      load();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to update");
    } finally {
      setActionId(null);
    }
  };

  if (ready && !isSeller) {
    return (
      <div className="rounded-xl border border-amber-200 bg-amber-50 px-4 py-6 text-amber-800">
        <p className="font-medium">Access denied.</p>
        <p className="mt-1 text-sm">This page is for sellers only.</p>
      </div>
    );
  }

  return (
    <div>
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-semibold text-slate-800">My businesses</h1>
        <button
          type="button"
          onClick={openCreate}
          className="inline-flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700"
        >
          <Plus className="h-4 w-4" aria-hidden />
          Add business
        </button>
      </div>

      {error && (
        <div className="mb-4 rounded-lg bg-amber-50 px-4 py-3 text-sm text-amber-800">
          {error}
        </div>
      )}

      {loading ? (
        <div className="flex items-center gap-2 py-12 text-slate-500">
          <Loader2 className="h-6 w-6 animate-spin" aria-hidden />
          Loading…
        </div>
      ) : list.length === 0 ? (
        <div className="rounded-xl border border-slate-200 bg-white py-16 text-center">
          <Store className="mx-auto h-12 w-12 text-slate-300" aria-hidden />
          <p className="mt-4 text-slate-600">No businesses yet.</p>
          <p className="mt-1 text-sm text-slate-500">Add a listing to get started.</p>
          <button
            type="button"
            onClick={openCreate}
            className="mt-4 inline-flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700"
          >
            <Plus className="h-4 w-4" aria-hidden />
            Add business
          </button>
        </div>
      ) : (
        <div className="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
          <table className="min-w-full divide-y divide-slate-200">
            <thead className="bg-slate-50">
              <tr>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                  Listing
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                  Status
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                  Price
                </th>
                <th className="px-4 py-3 text-right text-xs font-medium text-slate-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 bg-white">
              {list.map((b) => (
                <tr key={b._id} className="hover:bg-slate-50/50">
                  <td className="px-4 py-3">
                    <div>
                      <p className="font-medium text-slate-800">{b.name}</p>
                      {b.category && (
                        <p className="flex items-center gap-1 text-sm text-slate-500">
                          <Tag className="h-3.5 w-3.5" aria-hidden />
                          {formatCategory(b.category)}
                        </p>
                      )}
                      {b.location && (
                        <p className="flex items-center gap-1 text-sm text-slate-500">
                          <MapPin className="h-3.5 w-3.5 shrink-0" aria-hidden />
                          {b.location}
                        </p>
                      )}
                    </div>
                  </td>
                  <td className="px-4 py-3">
                    <span
                      className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${
                        b.isSold
                          ? "bg-slate-100 text-slate-700"
                          : b.status === "approved"
                            ? "bg-emerald-100 text-emerald-800"
                            : b.status === "rejected"
                              ? "bg-red-100 text-red-800"
                              : "bg-amber-100 text-amber-800"
                      }`}
                    >
                      {b.isSold ? "Sold" : b.status ?? "pending"}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-sm text-slate-700">
                    {formatPrice(b.askingPrice)}
                  </td>
                  <td className="px-4 py-3 text-right">
                    <div className="flex flex-wrap items-center justify-end gap-2">
                      <Link
                        href={`/business/${b._id}`}
                        className="inline-flex items-center gap-1 rounded-lg border border-slate-200 bg-white px-2 py-1.5 text-sm text-slate-600 hover:bg-slate-50"
                      >
                        <Eye className="h-4 w-4" aria-hidden />
                        View
                      </Link>
                      {!b.isSold && (
                        <button
                          type="button"
                          onClick={() => openEdit(b)}
                          className="inline-flex items-center gap-1 rounded-lg border border-slate-200 bg-white px-2 py-1.5 text-sm text-slate-600 hover:bg-slate-50"
                        >
                          <Pencil className="h-4 w-4" aria-hidden />
                          Edit
                        </button>
                      )}
                      {b.status === "approved" && !b.isSold && (
                        <button
                          type="button"
                          onClick={() => handleMarkSold(b, true)}
                          disabled={actionId === b._id}
                          className="inline-flex items-center gap-1 rounded-lg bg-emerald-600 px-2 py-1.5 text-sm text-white hover:bg-emerald-700 disabled:opacity-50"
                        >
                          {actionId === b._id ? (
                            <Loader2 className="h-4 w-4 animate-spin" aria-hidden />
                          ) : (
                            <CheckCircle className="h-4 w-4" aria-hidden />
                          )}
                          Mark sold
                        </button>
                      )}
                      {b.isSold && (
                        <button
                          type="button"
                          onClick={() => handleMarkSold(b, false)}
                          disabled={actionId === b._id}
                          className="inline-flex items-center gap-1 rounded-lg bg-slate-600 px-2 py-1.5 text-sm text-white hover:bg-slate-700 disabled:opacity-50"
                        >
                          {actionId === b._id ? (
                            <Loader2 className="h-4 w-4 animate-spin" aria-hidden />
                          ) : (
                            <XCircle className="h-4 w-4" aria-hidden />
                          )}
                          Mark available
                        </button>
                      )}
                      <button
                        type="button"
                        onClick={() => handleDelete(b)}
                        disabled={actionId === b._id}
                        className="inline-flex items-center gap-1 rounded-lg border border-red-200 bg-white px-2 py-1.5 text-sm text-red-600 hover:bg-red-50 disabled:opacity-50"
                      >
                        {actionId === b._id ? (
                          <Loader2 className="h-4 w-4 animate-spin" aria-hidden />
                        ) : (
                          <Trash2 className="h-4 w-4" aria-hidden />
                        )}
                        Delete
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {pagination.pages > 1 && (
        <div className="mt-4 flex items-center justify-between text-sm text-slate-500">
          <span>
            Page {page} of {pagination.pages} ({pagination.total} total)
          </span>
          <div className="flex gap-2">
            <button
              type="button"
              onClick={() => setPage((p) => Math.max(1, p - 1))}
              disabled={page <= 1}
              className="rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-slate-600 hover:bg-slate-50 disabled:opacity-50"
            >
              Previous
            </button>
            <button
              type="button"
              onClick={() => setPage((p) => Math.min(pagination.pages, p + 1))}
              disabled={page >= pagination.pages}
              className="rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-slate-600 hover:bg-slate-50 disabled:opacity-50"
            >
              Next
            </button>
          </div>
        </div>
      )}

      {modal && (
        <div
          className="fixed inset-0 z-10 flex items-center justify-center bg-black/40 p-4"
          onClick={closeModal}
        >
          <div
            className="w-full max-w-lg rounded-xl bg-white p-6 shadow-lg"
            onClick={(e) => e.stopPropagation()}
          >
            <h2 className="mb-2 text-lg font-semibold text-slate-800">
              {editing ? "Edit business" : "Add business"}
            </h2>
            {error && (
              <div className="mb-4 rounded-lg bg-amber-50 px-3 py-2 text-sm text-amber-800">
                {error}
              </div>
            )}
            {/* Step indicator */}
            <div className="mb-6 flex items-center gap-2">
              {STEPS.map((s, i) => (
                <div key={s.id} className="flex items-center gap-1">
                  <span
                    className={`flex h-8 w-8 items-center justify-center rounded-full text-sm font-medium ${
                      step >= s.id ? "bg-blue-600 text-white" : "bg-slate-200 text-slate-500"
                    }`}
                  >
                    {s.id}
                  </span>
                  {i < STEPS.length - 1 && (
                    <ChevronRight className="h-4 w-4 text-slate-300" aria-hidden />
                  )}
                </div>
              ))}
              <span className="ml-2 text-sm text-slate-500">{STEPS[step - 1].title}</span>
            </div>

            <form onSubmit={handleSubmit} className="flex flex-col gap-4">
              {/* Step 1: Basic info */}
              {step === 1 && (
                <>
                  <div>
                    <label className="mb-1 block text-sm font-medium text-slate-600">Name *</label>
                    <input
                      type="text"
                      value={form.name ?? ""}
                      onChange={(e) => setForm((f) => ({ ...f, name: e.target.value }))}
                      className="w-full rounded-lg border border-slate-300 px-3 py-2 text-slate-800"
                      required
                      placeholder="Business name"
                    />
                  </div>
                  <div>
                    <label className="mb-1 block text-sm font-medium text-slate-600">Category</label>
                    <select
                      value={form.category ?? ""}
                      onChange={(e) => setForm((f) => ({ ...f, category: e.target.value }))}
                      className="w-full rounded-lg border border-slate-300 px-3 py-2 text-slate-800"
                    >
                      <option value="">— Select —</option>
                      {CATEGORIES.map((c) => (
                        <option key={c} value={c}>
                          {formatCategory(c)}
                        </option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label className="mb-1 block text-sm font-medium text-slate-600">Location</label>
                    <input
                      type="text"
                      value={form.location ?? ""}
                      onChange={(e) => setForm((f) => ({ ...f, location: e.target.value }))}
                      className="w-full rounded-lg border border-slate-300 px-3 py-2 text-slate-800"
                      placeholder="City, region or address"
                    />
                  </div>
                </>
              )}

              {/* Step 2: Details */}
              {step === 2 && (
                <>
                  <div>
                    <label className="mb-1 block text-sm font-medium text-slate-600">Asking price ($)</label>
                    <input
                      type="number"
                      min={0}
                      step={1}
                      value={form.askingPrice ?? ""}
                      onChange={(e) =>
                        setForm((f) => ({
                          ...f,
                          askingPrice: e.target.value === "" ? undefined : Number(e.target.value),
                        }))
                      }
                      className="w-full rounded-lg border border-slate-300 px-3 py-2 text-slate-800"
                      placeholder="0"
                    />
                  </div>
                  <div>
                    <label className="mb-1 block text-sm font-medium text-slate-600">Annual revenue ($)</label>
                    <input
                      type="number"
                      min={0}
                      step={1}
                      value={form.annualRevenue ?? ""}
                      onChange={(e) =>
                        setForm((f) => ({
                          ...f,
                          annualRevenue: e.target.value === "" ? undefined : Number(e.target.value),
                        }))
                      }
                      className="w-full rounded-lg border border-slate-300 px-3 py-2 text-slate-800"
                      placeholder="Optional"
                    />
                  </div>
                  <div>
                    <label className="mb-1 block text-sm font-medium text-slate-600">Description</label>
                    <textarea
                      rows={3}
                      value={form.description ?? ""}
                      onChange={(e) => setForm((f) => ({ ...f, description: e.target.value }))}
                      className="w-full rounded-lg border border-slate-300 px-3 py-2 text-slate-800"
                      placeholder="Describe your business"
                    />
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="mb-1 block text-sm font-medium text-slate-600">Phone</label>
                      <input
                        type="text"
                        value={form.phone ?? ""}
                        onChange={(e) => setForm((f) => ({ ...f, phone: e.target.value }))}
                        className="w-full rounded-lg border border-slate-300 px-3 py-2 text-slate-800"
                      />
                    </div>
                    <div>
                      <label className="mb-1 block text-sm font-medium text-slate-600">Email</label>
                      <input
                        type="email"
                        value={form.email ?? ""}
                        onChange={(e) => setForm((f) => ({ ...f, email: e.target.value }))}
                        className="w-full rounded-lg border border-slate-300 px-3 py-2 text-slate-800"
                      />
                    </div>
                  </div>
                  <div>
                    <label className="mb-1 block text-sm font-medium text-slate-600">Website</label>
                    <input
                      type="url"
                      value={form.website ?? ""}
                      onChange={(e) => setForm((f) => ({ ...f, website: e.target.value }))}
                      className="w-full rounded-lg border border-slate-300 px-3 py-2 text-slate-800"
                      placeholder="https://"
                    />
                  </div>
                  <div>
                    <label className="mb-1 block text-sm font-medium text-slate-600">Address</label>
                    <input
                      type="text"
                      value={form.address ?? ""}
                      onChange={(e) => setForm((f) => ({ ...f, address: e.target.value }))}
                      className="w-full rounded-lg border border-slate-300 px-3 py-2 text-slate-800"
                      placeholder="Full address"
                    />
                  </div>
                </>
              )}

              {/* Step 3: Images (optional) */}
              {step === 3 && (
                <>
                  <p className="text-sm text-slate-600">
                    Add up to {MAX_IMAGES} images (max {MAX_FILE_SIZE_MB}MB each). Optional.
                  </p>
                  <label className="flex cursor-pointer flex-col items-center justify-center rounded-xl border-2 border-dashed border-slate-200 bg-slate-50 py-8 transition-colors hover:border-blue-300 hover:bg-slate-100">
                    <input
                      type="file"
                      accept="image/*"
                      multiple
                      onChange={handleFileChange}
                      className="hidden"
                    />
                    <ImagePlus className="mb-2 h-10 w-10 text-slate-400" aria-hidden />
                    <span className="text-sm font-medium text-slate-600">Choose images</span>
                    <span className="mt-1 text-xs text-slate-500">
                      or drag and drop (optional)
                    </span>
                  </label>
                  {editing && (editing.images?.length ?? 0) > 0 && (
                    <div>
                      <p className="mb-2 text-sm font-medium text-slate-600">Current images</p>
                      <div className="flex flex-wrap gap-2">
                        {editing.images?.map((img, i) => (
                          <div key={i} className="relative h-20 w-20 overflow-hidden rounded-lg border border-slate-200">
                            <img src={img.url} alt="" className="h-full w-full object-cover" />
                          </div>
                        ))}
                      </div>
                    </div>
                  )}
                  {filePreviews.length > 0 && (
                    <div>
                      <p className="mb-2 text-sm font-medium text-slate-600">New images ({filePreviews.length})</p>
                      <div className="flex flex-wrap gap-2">
                        {filePreviews.map((url, i) => (
                          <div key={i} className="relative">
                            <div className="h-20 w-20 overflow-hidden rounded-lg border border-slate-200">
                              <img src={url} alt="" className="h-full w-full object-cover" />
                            </div>
                            <button
                              type="button"
                              onClick={() => removeFile(i)}
                              className="absolute -right-1 -top-1 flex h-5 w-5 items-center justify-center rounded-full bg-red-500 text-white hover:bg-red-600"
                              aria-label="Remove image"
                            >
                              <X className="h-3 w-3" aria-hidden />
                            </button>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}
                </>
              )}

              <div className="flex gap-2 pt-2">
                <button
                  type="button"
                  onClick={closeModal}
                  className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-600"
                >
                  Cancel
                </button>
                {step > 1 && (
                  <button
                    type="button"
                    onClick={goBack}
                    className="inline-flex items-center gap-1 rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-600"
                  >
                    <ChevronLeft className="h-4 w-4" aria-hidden />
                    Back
                  </button>
                )}
                <button
                  type="submit"
                  disabled={submitLoading}
                  className="ml-auto inline-flex items-center gap-1 rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50"
                >
                  {submitLoading ? (
                    <>
                      <Loader2 className="h-4 w-4 animate-spin" aria-hidden />
                      Saving…
                    </>
                  ) : step < 3 ? (
                    <>
                      Next
                      <ChevronRight className="h-4 w-4" aria-hidden />
                    </>
                  ) : editing ? (
                    "Save"
                  ) : (
                    "Create"
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
