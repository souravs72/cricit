/**
 * RBAC: roles are named sets of permissions; adding a role is a data change, not a code change.
 * Keep in sync with the permission matrix in the implementation plan and admin/src/app/(dashboard)/nav.ts.
 */
export const Permission = {
  DASHBOARD_VIEW: "dashboard:view",
  POSTS_WRITE: "posts:write",
  POSTS_PUBLISH: "posts:publish",
  NXTSPOT_CREATE: "nxtspot:create",
  PUSH_SEND: "push:send",
  SOURCES_MANAGE: "sources:manage",
  ADS_MANAGE: "ads:manage",
  SETTINGS_MANAGE: "settings:manage",
  ADMINS_MANAGE: "admins:manage",
  AUDIT_VIEW: "audit:view",
} as const;
export type Permission = (typeof Permission)[keyof typeof Permission];

export type Role = "owner" | "editor" | "viewer";

const ALL = Object.values(Permission);

export const ROLE_PERMISSIONS: Record<Role, ReadonlySet<Permission>> = {
  owner: new Set(ALL),
  editor: new Set([
    Permission.DASHBOARD_VIEW,
    Permission.POSTS_WRITE,
    Permission.POSTS_PUBLISH,
    Permission.NXTSPOT_CREATE,
    Permission.PUSH_SEND,
    Permission.SOURCES_MANAGE,
  ]),
  viewer: new Set([Permission.DASHBOARD_VIEW]),
};

export function permissionsFor(role: Role): Permission[] {
  return [...ROLE_PERMISSIONS[role]];
}
