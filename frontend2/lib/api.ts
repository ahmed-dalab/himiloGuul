// Must be absolute so browser requests hit the backend, not the Next.js server
const BASE_URL =
  typeof process.env.NEXT_PUBLIC_API_URL === "string" &&
  process.env.NEXT_PUBLIC_API_URL.startsWith("http")
    ? process.env.NEXT_PUBLIC_API_URL.replace(/\/$/, "")
    : "http://localhost:3001/api";

function getToken(): string | null {
  if (typeof window === "undefined") return null;
  return localStorage.getItem("token");
}

export async function api<T = unknown>(
  path: string,
  options: RequestInit & {
    params?: Record<string, string | number | undefined>;
  } = {},
): Promise<T> {
  const { params, ...init } = options;
  let url = path.startsWith("http") ? path : `${BASE_URL}${path}`;
  if (params && Object.keys(params).length > 0) {
    const search = new URLSearchParams();
    for (const [k, v] of Object.entries(params))
      if (v != null && v !== "") search.set(k, String(v));
    const qs = search.toString();
    if (qs) url += (url.includes("?") ? "&" : "?") + qs;
  }
  const token = getToken();
  const headers: HeadersInit = {
    "Content-Type": "application/json",
    ...(init.headers as Record<string, string>),
  };
  if (token)
    (headers as Record<string, string>)["Authorization"] = `Bearer ${token}`;

  const res = await fetch(url, { ...init, headers });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    const d = data as { message?: string; error?: string };
    const message = d?.message || d?.error || res.statusText || "Request failed";
    throw new Error(message);
  }
  return data as T;
}

/** Send FormData (e.g. for multipart file upload). Do not set Content-Type. */
export async function apiFormData<T = unknown>(
  path: string,
  options: { method?: string; body: FormData } = {} as { method?: string; body: FormData },
): Promise<T> {
  const url = path.startsWith("http") ? path : `${BASE_URL}${path}`;
  const token = getToken();
  const headers: HeadersInit = {};
  if (token) (headers as Record<string, string>)["Authorization"] = `Bearer ${token}`;
  const res = await fetch(url, {
    method: options.method ?? "POST",
    body: options.body,
    headers,
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    const d = data as { message?: string; error?: string };
    const message = d?.message || d?.error || res.statusText || "Request failed";
    throw new Error(message);
  }
  return data as T;
}

// Auth
export const authApi = {
  login: (email: string, password: string) =>
    api<{ token: string; user: User }>("/auth/login", {
      method: "POST",
      body: JSON.stringify({ email, password }),
    }),
  register: (name: string, email: string, password: string, role?: string) =>
    api<{ token: string; user: User }>("/auth/register", {
      method: "POST",
      body: JSON.stringify({ name, email, password, role: role ?? "buyer" }),
    }),
};

// Businesses (public list/get; seller: my list, create, update, delete, mark sold)
export const businessesApi = {
  list: (params?: {
    page?: number;
    limit?: number;
    search?: string;
    category?: string;
  }) =>
    api<{
      data: Business[];
      pagination: { page: number; limit: number; total: number; pages: number };
    }>("/business", {
      params: params as Record<string, string | number | undefined>,
    }),
  get: (id: string) => api<{ data: Business }>(`/business/${id}`),
  myList: (params?: {
    page?: number;
    limit?: number;
    status?: string;
    sortBy?: string;
    sortOrder?: string;
  }) =>
    api<{
      success: boolean;
      data: Business[];
      pagination: { page: number; limit: number; total: number; pages: number };
    }>("/business/my", { params: params as Record<string, string | number> }),
  create: (body: Partial<Business> & { name: string }) =>
    api<{ success: boolean; data: Business }>("/business", {
      method: "POST",
      body: JSON.stringify(body),
    }),
  /** Create with optional images (FormData). Field name for files: "images". */
  createWithFormData: (formData: FormData) =>
    apiFormData<{ success: boolean; data: Business }>("/business", {
      method: "POST",
      body: formData,
    }),
  update: (id: string, body: Partial<Business>) =>
    api<{ success: boolean; data: Business }>(`/business/${id}`, {
      method: "PUT",
      body: JSON.stringify(body),
    }),
  /** Update with optional new images (FormData). Appends to existing images. Field name: "images". */
  updateWithFormData: (id: string, formData: FormData) =>
    apiFormData<{ success: boolean; data: Business }>(`/business/${id}`, {
      method: "PUT",
      body: formData,
    }),
  delete: (id: string) =>
    api<{ success: boolean }>(`/business/${id}`, { method: "DELETE" }),
  markSold: (id: string, isSold: boolean) =>
    api<{ success: boolean; data: Business }>(`/business/${id}/sold`, {
      method: "PUT",
      body: JSON.stringify({ isSold }),
    }),
};

// Contacts (seller/buyer: my contacts, get, update status, delete)
export const contactsApi = {
  myList: (params?: {
    page?: number;
    limit?: number;
    status?: string;
    role?: "buyer" | "seller";
    sortBy?: string;
    sortOrder?: string;
  }) =>
    api<{
      success: boolean;
      data: Contact[];
      pagination: { page: number; limit: number; total: number; pages: number };
    }>("/contacts/my", { params: params as Record<string, string | number> }),
  get: (id: string) =>
    api<{ success: boolean; data: Contact }>(`/contacts/${id}`),
  update: (id: string, body: { status?: string; message?: string }) =>
    api<{ success: boolean; data: Contact }>(`/contacts/${id}`, {
      method: "PUT",
      body: JSON.stringify(body),
    }),
  delete: (id: string) =>
    api<{ success: boolean }>(`/contacts/${id}`, { method: "DELETE" }),
};

// Users
export const usersApi = {
  list: (params?: {
    role?: string;
    search?: string;
    page?: number;
    limit?: number;
  }) =>
    api<{
      data: User[];
      pagination: { page: number; limit: number; total: number; pages: number };
    }>("/users", {
      params: params as Record<string, string>,
    }),
  create: (body: {
    name: string;
    email: string;
    password: string;
    role: string;
  }) =>
    api<{ user: User }>("/users", {
      method: "POST",
      body: JSON.stringify(body),
    }),
  get: (id: string) => api<{ user: User }>(`/users/${id}`),
  update: (id: string, body: Partial<User & { role: string }>) =>
    api<{ user: User }>(`/users/${id}`, {
      method: "PUT",
      body: JSON.stringify(body),
    }),
  delete: (id: string) => api(`/users/${id}`, { method: "DELETE" }),
};

// Roles
export const rolesApi = {
  list: () => api<{ data: Role[]; count: number }>("/roles"),
  create: (body: { name: string }) =>
    api<{ data: Role }>("/roles", {
      method: "POST",
      body: JSON.stringify(body),
    }),
  get: (id: string) => api<{ data: Role }>(`/roles/${id}`),
  update: (id: string, body: { name: string }) =>
    api<{ data: Role }>(`/roles/${id}`, {
      method: "PUT",
      body: JSON.stringify(body),
    }),
  delete: (id: string) => api(`/roles/${id}`, { method: "DELETE" }),
};

// Menus
export const menusApi = {
  list: (params?: { parentId?: string }) =>
    api<{ menus: Menu[]; count: number }>("/menus", {
      params: params as Record<string, string>,
    }),
  me: () => api<{ menus: Menu[]; count: number }>("/menus/me"),
  create: (body: { name: string; path: string; parentId?: string }) =>
    api<{ menu: Menu }>("/menus", {
      method: "POST",
      body: JSON.stringify(body),
    }),
  get: (id: string) => api<{ menu: Menu }>(`/menus/${id}`),
  update: (id: string, body: Partial<Menu>) =>
    api<{ menu: Menu }>(`/menus/${id}`, {
      method: "PUT",
      body: JSON.stringify(body),
    }),
  delete: (id: string) => api(`/menus/${id}`, { method: "DELETE" }),
};

// Permissions
export const permissionsApi = {
  list: (params?: { menuId?: string; page?: number; limit?: number }) =>
    api<{
      data: Permission[];
      pagination: { page: number; limit: number; total: number; pages: number };
    }>("/permissions", { params: params as Record<string, string> }),
  create: (body: { name: string; menuId: string }) =>
    api<{ data: Permission }>("/permissions", {
      method: "POST",
      body: JSON.stringify(body),
    }),
  get: (id: string) => api<{ data: Permission }>(`/permissions/${id}`),
  update: (id: string, body: { name?: string; menuId?: string }) =>
    api<{ data: Permission }>(`/permissions/${id}`, {
      method: "PUT",
      body: JSON.stringify(body),
    }),
  delete: (id: string) => api(`/permissions/${id}`, { method: "DELETE" }),
};

// Admin (admin role only)
export const adminApi = {
  dashboardStats: () =>
    api<{
      success: boolean;
      data: {
        totalUsers: number;
        totalActiveBusinesses: number;
        dealsClosed: number;
      };
    }>("/admin/dashboard"),
  activities: (params?: { limit?: number }) =>
    api<{ success: boolean; data: Activity[] }>("/admin/activities", {
      params: params as Record<string, number>,
    }),
  listBusinesses: (params?: {
    page?: number;
    limit?: number;
    status?: string;
    category?: string;
    sortBy?: string;
    sortOrder?: string;
  }) =>
    api<{
      success: boolean;
      data: Business[];
      pagination: { page: number; limit: number; total: number; pages: number };
    }>("/admin/businesses", {
      params: params as Record<string, string | number>,
    }),
  listPendingBusinesses: (params?: { page?: number; limit?: number }) =>
    api<{
      success: boolean;
      data: Business[];
      pagination: { page: number; limit: number; total: number; pages: number };
    }>("/admin/businesses/pending", {
      params: params as Record<string, number>,
    }),
  approveBusiness: (id: string) =>
    api<{ success: boolean; data: Business }>(
      `/admin/businesses/${id}/approve`,
      { method: "PUT" },
    ),
  rejectBusiness: (id: string) =>
    api<{ success: boolean; data: Business }>(
      `/admin/businesses/${id}/reject`,
      { method: "PUT" },
    ),
  listUsers: (params?: {
    page?: number;
    limit?: number;
    roleId?: string;
    isBanned?: boolean;
    search?: string;
    sortBy?: string;
    sortOrder?: string;
  }) =>
    api<{
      success: boolean;
      data: User[];
      pagination: { page: number; limit: number; total: number; pages: number };
    }>("/admin/users", {
      params: params as Record<string, string | number | boolean>,
    }),
  banUser: (id: string, isBanned: boolean) =>
    api<{ success: boolean; data: User }>(`/admin/users/${id}/ban`, {
      method: "PUT",
      body: JSON.stringify({ isBanned }),
    }),
  deleteUser: (id: string) =>
    api<{ success: boolean }>(`/admin/users/${id}`, { method: "DELETE" }),
  listContacts: (params?: {
    page?: number;
    limit?: number;
    status?: string;
    sortBy?: string;
    sortOrder?: string;
  }) =>
    api<{
      success: boolean;
      data: Contact[];
      pagination: { page: number; limit: number; total: number; pages: number };
    }>("/admin/contacts", {
      params: params as Record<string, string | number>,
    }),
  deleteContact: (id: string) =>
    api<{ success: boolean }>(`/admin/contacts/${id}`, { method: "DELETE" }),
};

// Role-Permissions
export const rolePermissionsApi = {
  list: (params?: { roleId?: string; permissionId?: string; limit?: number }) =>
    api<{
      data: RolePermission[];
      pagination?: {
        page: number;
        limit: number;
        total: number;
        pages: number;
      };
    }>("/role-permissions", {
      params: { ...params, limit: String(params?.limit ?? 500) } as Record<
        string,
        string
      >,
    }),
  create: (body: { roleId: string; permissionId: string }) =>
    api<{ data: RolePermission }>("/role-permissions", {
      method: "POST",
      body: JSON.stringify(body),
    }),
  delete: (roleId: string, permissionId: string) =>
    api(`/role-permissions/role/${roleId}/permission/${permissionId}`, {
      method: "DELETE",
    }),
  deleteById: (id: string) =>
    api(`/role-permissions/${id}`, { method: "DELETE" }),
};

export type User = {
  _id: string;
  name: string;
  email: string;
  roleId?: { _id: string; name: string } | string;
  role?: string;
  isBanned?: boolean;
  phone?: string;
  createdAt?: string;
};

export type Role = { _id: string; name: string };

export type Menu = {
  _id: string;
  name: string;
  path: string;
  parentId?: string | null;
  isActive?: boolean;
  icon?: string;
};

export type Permission = {
  _id: string;
  name: string;
  menuId: string | { _id: string; name: string; path?: string };
};

export type RolePermission = {
  _id: string;
  roleId: string | { _id: string; name: string };
  permissionId:
    | string
    | {
        _id: string;
        name: string;
        menuId?: string | { _id: string; name: string; path: string };
      };
};

export type Business = {
  _id: string;
  name: string;
  description?: string;
  address?: string;
  phone?: string;
  email?: string;
  website?: string;
  location?: string;
  category?: string;
  askingPrice?: number;
  annualRevenue?: number;
  images?: { url: string; publicId: string }[];
  status?: string;
  isSold?: boolean;
  owner?: { _id: string; name: string; email?: string; phone?: string };
  createdAt?: string;
  updatedAt?: string;
};

export type Activity = {
  _id: string;
  type: string;
  description: string;
  relatedId?: string;
  relatedModel?: string;
  metadata?: Record<string, unknown>;
  createdAt?: string;
};

export type Contact = {
  _id: string;
  name: string;
  email: string;
  phone?: string;
  message: string;
  status?: string;
  buyerRef?: { _id: string; name: string; email?: string; phone?: string };
  sellerRef?: { _id: string; name: string; email?: string; phone?: string };
  businessRef?: {
    _id: string;
    name: string;
    category?: string;
    askingPrice?: number;
    location?: string;
  };
  createdAt?: string;
};
