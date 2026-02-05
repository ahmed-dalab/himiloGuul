"use client";

import Link from "next/link";
import { useAuth } from "@/lib/auth-context";
import { Store, LogIn, UserPlus, LogOut } from "lucide-react";

export function Topbar() {
  const { token, user, logout } = useAuth();

  return (
    <header className="sticky top-0 z-50 border-b border-slate-200 bg-white/95 backdrop-blur">
      <div className="mx-auto flex h-14 max-w-6xl items-center justify-between px-4">
        <Link href="/" className="flex items-center gap-2 text-slate-800 hover:text-slate-600">
          <Store className="h-7 w-7 text-blue-600" aria-hidden />
          <span className="text-lg font-semibold tracking-tight">HimiloGuul</span>
        </Link>
        <nav className="flex items-center gap-2">
          {token ? (
            <>
              <span className="mr-2 text-sm text-slate-600">{user?.name ?? user?.email}</span>
              <Link
                href="/dashboard"
                className="rounded-lg px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-100"
              >
                Dashboard
              </Link>
              <button
                type="button"
                onClick={() => logout()}
                className="flex items-center gap-1.5 rounded-lg px-3 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100"
              >
                <LogOut className="h-4 w-4" aria-hidden />
                Logout
              </button>
            </>
          ) : (
            <>
              <Link
                href="/login"
                className="flex items-center gap-1.5 rounded-lg px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-100"
              >
                <LogIn className="h-4 w-4" aria-hidden />
                Login
              </Link>
              <Link
                href="/register"
                className="flex items-center gap-1.5 rounded-lg bg-blue-600 px-3 py-2 text-sm font-medium text-white hover:bg-blue-700"
              >
                <UserPlus className="h-4 w-4" aria-hidden />
                Register
              </Link>
            </>
          )}
        </nav>
      </div>
    </header>
  );
}
