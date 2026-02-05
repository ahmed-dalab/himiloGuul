"use client";

import Link from "next/link";
import { Store } from "lucide-react";

export function Footer() {
  return (
    <footer className="border-t border-slate-200 bg-white mt-auto">
      <div className="mx-auto max-w-6xl px-4 py-8">
        <div className="flex flex-col items-center justify-between gap-4 sm:flex-row">
          <Link href="/" className="flex items-center gap-2 text-slate-600 hover:text-slate-800">
            <Store className="h-5 w-5 text-blue-600" aria-hidden />
            <span className="font-medium">HimiloGuul</span>
          </Link>
          <p className="text-sm text-slate-500">
            Browse and discover businesses for sale.
          </p>
          <div className="flex gap-6 text-sm text-slate-600">
            <Link href="/" className="hover:text-slate-800">Businesses</Link>
            <Link href="/login" className="hover:text-slate-800">Login</Link>
            <Link href="/register" className="hover:text-slate-800">Register</Link>
          </div>
        </div>
        <p className="mt-6 border-t border-slate-100 pt-6 text-center text-xs text-slate-400">
          © {new Date().getFullYear()} HimiloGuul. All rights reserved.
        </p>
      </div>
    </footer>
  );
}
