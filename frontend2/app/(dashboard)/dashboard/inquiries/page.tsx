"use client";

import { useEffect, useState } from "react";
import { useAuth } from "@/lib/auth-context";
import { contactsApi, type Contact } from "@/lib/api";
import { MessageSquare, Loader2, Trash2, ChevronLeft, ChevronRight } from "lucide-react";

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

export default function InquiriesPage() {
  const { user, ready } = useAuth();
  const isSeller = user?.role === "seller";
  const [contacts, setContacts] = useState<Contact[]>([]);
  const [pagination, setPagination] = useState({
    page: 1,
    limit: 10,
    total: 0,
    pages: 0,
  });
  const [page, setPage] = useState(1);
  const limit = 10;
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [updatingId, setUpdatingId] = useState<string | null>(null);

  const fetchContacts = () => {
    setLoading(true);
    setError("");
    contactsApi
      .myList({ page, limit, role: "seller" })
      .then((res) => {
        setContacts(res.data);
        setPagination(res.pagination);
      })
      .catch((e) =>
        setError(e instanceof Error ? e.message : "Failed to load inquiries")
      )
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    if (!isSeller) return;
    fetchContacts();
  }, [isSeller, page]);

  const handleStatusChange = async (c: Contact, status: string) => {
    setUpdatingId(c._id);
    try {
      await contactsApi.update(c._id, { status });
      fetchContacts();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to update status");
    } finally {
      setUpdatingId(null);
    }
  };

  const handleDelete = async (c: Contact) => {
    if (!confirm(`Delete this inquiry?`)) return;
    setDeletingId(c._id);
    try {
      await contactsApi.delete(c._id);
      fetchContacts();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to delete");
    } finally {
      setDeletingId(null);
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
      <h1 className="mb-2 text-2xl font-semibold text-slate-800">Inquiries</h1>
      <p className="mb-6 text-slate-600">
        Inquiries from buyers about your listed businesses. You can update status or delete.
      </p>

      {error && (
        <div className="mb-6 rounded-lg bg-amber-50 px-4 py-3 text-sm text-amber-800">
          {error}
        </div>
      )}

      {loading ? (
        <div className="flex items-center gap-2 py-12 text-slate-500">
          <Loader2 className="h-6 w-6 animate-spin" aria-hidden />
          Loading…
        </div>
      ) : contacts.length === 0 ? (
        <div className="rounded-xl border border-slate-200 bg-white py-16 text-center">
          <MessageSquare className="mx-auto h-12 w-12 text-slate-300" aria-hidden />
          <p className="mt-4 text-slate-600">No inquiries yet.</p>
          <p className="mt-1 text-sm text-slate-500">
            When buyers contact you about a listing, they will appear here.
          </p>
        </div>
      ) : (
        <>
          <div className="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
            <table className="min-w-full divide-y divide-slate-200">
              <thead className="bg-slate-50">
                <tr>
                  <th className="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                    From / Business
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                    Message
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                    Status
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                    Date
                  </th>
                  <th className="px-4 py-3 text-right text-xs font-medium text-slate-500 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 bg-white">
                {contacts.map((c) => (
                  <tr key={c._id} className="hover:bg-slate-50/50">
                    <td className="px-4 py-3">
                      <div>
                        <p className="font-medium text-slate-800">{c.name}</p>
                        <p className="text-sm text-slate-500">{c.email}</p>
                        {c.businessRef &&
                          typeof c.businessRef === "object" && (
                            <p className="mt-1 text-sm text-slate-600">
                              Re: {c.businessRef.name}
                            </p>
                          )}
                      </div>
                    </td>
                    <td className="max-w-xs px-4 py-3">
                      <p
                        className="truncate text-sm text-slate-600"
                        title={c.message}
                      >
                        {c.message}
                      </p>
                    </td>
                    <td className="px-4 py-3">
                      <select
                        value={c.status ?? "pending"}
                        onChange={(e) =>
                          handleStatusChange(c, e.target.value)
                        }
                        disabled={updatingId === c._id}
                        className={`rounded-full border px-2 py-0.5 text-xs font-medium focus:outline-none focus:ring-1 ${
                          c.status === "closed"
                            ? "border-slate-200 bg-slate-100 text-slate-700"
                            : c.status === "responded"
                              ? "border-blue-200 bg-blue-100 text-blue-800"
                              : "border-amber-200 bg-amber-100 text-amber-800"
                        } disabled:opacity-50`}
                      >
                        <option value="pending">Pending</option>
                        <option value="responded">Responded</option>
                        <option value="closed">Closed</option>
                      </select>
                      {updatingId === c._id && (
                        <Loader2
                          className="ml-1 inline h-3.5 w-3.5 animate-spin text-slate-400"
                          aria-hidden
                        />
                      )}
                    </td>
                    <td className="px-4 py-3 text-sm text-slate-500">
                      {formatDate(c.createdAt)}
                    </td>
                    <td className="px-4 py-3 text-right">
                      <button
                        type="button"
                        onClick={() => handleDelete(c)}
                        disabled={deletingId === c._id}
                        className="inline-flex items-center gap-1 rounded-lg border border-red-200 bg-white px-2 py-1.5 text-sm text-red-600 hover:bg-red-50 disabled:opacity-50"
                      >
                        {deletingId === c._id ? (
                          <Loader2
                            className="h-4 w-4 animate-spin"
                            aria-hidden
                          />
                        ) : (
                          <Trash2 className="h-4 w-4" aria-hidden />
                        )}
                        Delete
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {pagination.pages > 1 && (
            <div className="mt-4 flex items-center justify-between">
              <p className="text-sm text-slate-500">
                Page {page} of {pagination.pages} ({pagination.total} total)
              </p>
              <div className="flex gap-2">
                <button
                  type="button"
                  onClick={() => setPage((p) => Math.max(1, p - 1))}
                  disabled={page <= 1}
                  className="inline-flex items-center rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-sm text-slate-600 hover:bg-slate-50 disabled:opacity-50"
                >
                  <ChevronLeft className="h-4 w-4" aria-hidden />
                  Previous
                </button>
                <button
                  type="button"
                  onClick={() =>
                    setPage((p) => Math.min(pagination.pages, p + 1))
                  }
                  disabled={page >= pagination.pages}
                  className="inline-flex items-center rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-sm text-slate-600 hover:bg-slate-50 disabled:opacity-50"
                >
                  Next
                  <ChevronRight className="h-4 w-4" aria-hidden />
                </button>
              </div>
            </div>
          )}
        </>
      )}
    </div>
  );
}
