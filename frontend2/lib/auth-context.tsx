"use client";

import React, { createContext, useCallback, useContext, useEffect, useState } from "react";
import type { User } from "./api";
import { authApi } from "./api";

type AuthState = {
  token: string | null;
  user: User | null;
  ready: boolean;
};

type AuthContextValue = AuthState & {
  login: (email: string, password: string) => Promise<void>;
  register: (name: string, email: string, password: string, role?: string) => Promise<void>;
  logout: () => void;
  setUser: (u: User | null) => void;
};

const AuthContext = createContext<AuthContextValue | null>(null);

const TOKEN_KEY = "token";
const USER_KEY = "user";

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [state, setState] = useState<AuthState>({
    token: null,
    user: null,
    ready: false,
  });

  useEffect(() => {
    const token = localStorage.getItem(TOKEN_KEY);
    const raw = localStorage.getItem(USER_KEY);
    let user: User | null = null;
    if (raw) try { user = JSON.parse(raw) as User; } catch { /* ignore */ }
    setState({ token, user, ready: true });
  }, []);

  const login = useCallback(async (email: string, password: string) => {
    const { token, user } = await authApi.login(email, password);
    localStorage.setItem(TOKEN_KEY, token);
    localStorage.setItem(USER_KEY, JSON.stringify(user));
    setState({ token, user, ready: true });
  }, []);

  const register = useCallback(async (name: string, email: string, password: string, role?: string) => {
    const { token, user } = await authApi.register(name, email, password, role ?? "buyer");
    localStorage.setItem(TOKEN_KEY, token);
    localStorage.setItem(USER_KEY, JSON.stringify(user));
    setState({ token, user, ready: true });
  }, []);

  const logout = useCallback(() => {
    localStorage.removeItem(TOKEN_KEY);
    localStorage.removeItem(USER_KEY);
    setState({ token: null, user: null, ready: true });
  }, []);

  const setUser = useCallback((user: User | null) => {
    setState((s) => ({ ...s, user }));
    if (user) localStorage.setItem(USER_KEY, JSON.stringify(user));
    else localStorage.removeItem(USER_KEY);
  }, []);

  return (
    <AuthContext.Provider
      value={{
        ...state,
        login,
        register,
        logout,
        setUser,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
