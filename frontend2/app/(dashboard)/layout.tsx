"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useAuth } from "@/lib/auth-context";
import { useEffect } from "react";

const NAV_ALL = [
  { href: "/dashboard", label: "Dashboard" },
  { href: "/", label: "Browse businesses", buyerOnly: true },
  { href: "/dashboard/my-inquiries", label: "My inquiries", buyerOnly: true },
  { href: "/dashboard/roles", label: "Roles", adminOnly: true },
  { href: "/dashboard/users", label: "Users", adminOnly: true },
  { href: "/dashboard/menus", label: "Menus", adminOnly: true },
  { href: "/dashboard/permissions", label: "Permissions", adminOnly: true },
  { href: "/dashboard/role-permissions", label: "Role Permissions", adminOnly: true },
  { href: "/dashboard/businesses", label: "Businesses", adminOnly: true },
  { href: "/dashboard/contacts", label: "Contacts", adminOnly: true },
  { href: "/dashboard/my-businesses", label: "My businesses", sellerOnly: true },
  { href: "/dashboard/inquiries", label: "Inquiries", sellerOnly: true },
];

function getNav(role: string | undefined) {
  const isAdmin = role === "admin";
  const isSeller = role === "seller";
  const isBuyer = role === "buyer";
  return NAV_ALL.filter((item) => {
    if ("adminOnly" in item && item.adminOnly) return isAdmin;
    if ("sellerOnly" in item && item.sellerOnly) return isSeller;
    if ("buyerOnly" in item && item.buyerOnly) return isBuyer;
    return true;
  });
}

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const { token, user, ready, logout } = useAuth();

  useEffect(() => {
    if (!ready) return;
    if (!token) {
      router.replace("/login");
      return;
    }
  }, [ready, token, router]);

  if (!ready || !token) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-slate-50">
        <div className="text-slate-500">Loading…</div>
      </div>
    );
  }

  return (
    <div className="flex min-h-screen bg-slate-50">
      <aside className="w-56 border-r border-slate-200 bg-white">
        <div className="sticky top-0 flex h-screen flex-col p-4">
          <div className="mb-6 font-semibold text-slate-800">HimiloGuul</div>
          <nav className="flex flex-col gap-1">
            {getNav(user?.role).map(({ href, label }) => (
              <Link
                key={href}
                href={href}
                className={`rounded-lg px-3 py-2 text-sm font-medium ${
                  pathname === href ? "bg-blue-50 text-blue-700" : "text-slate-600 hover:bg-slate-100"
                }`}
              >
                {label}
              </Link>
            ))}
          </nav>
          <div className="mt-auto border-t border-slate-200 pt-4">
            <div className="mb-2 truncate px-3 text-sm text-slate-500">{user?.email}</div>
            <button
              type="button"
              onClick={() => { logout(); router.replace("/login"); }}
              className="w-full rounded-lg px-3 py-2 text-left text-sm font-medium text-slate-600 hover:bg-slate-100"
            >
              Logout
            </button>
          </div>
        </div>
      </aside>
      <main className="flex-1 overflow-auto p-6">{children}</main>
    </div>
  );
}
