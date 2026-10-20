"""RBAC: roles are named sets of permissions. Adding a role is a data change, not a code change.

Keep this table in sync with the permission matrix in the implementation plan.
"""

from enum import StrEnum


class Permission(StrEnum):
    DASHBOARD_VIEW = "dashboard:view"
    POSTS_WRITE = "posts:write"
    POSTS_PUBLISH = "posts:publish"
    NXTSPOT_CREATE = "nxtspot:create"
    PUSH_SEND = "push:send"
    SOURCES_MANAGE = "sources:manage"
    ADS_MANAGE = "ads:manage"
    SETTINGS_MANAGE = "settings:manage"
    ADMINS_MANAGE = "admins:manage"
    AUDIT_VIEW = "audit:view"


class Role(StrEnum):
    OWNER = "owner"
    EDITOR = "editor"
    VIEWER = "viewer"


ROLE_PERMISSIONS: dict[Role, frozenset[Permission]] = {
    Role.OWNER: frozenset(Permission),
    Role.EDITOR: frozenset(
        {
            Permission.DASHBOARD_VIEW,
            Permission.POSTS_WRITE,
            Permission.POSTS_PUBLISH,
            Permission.NXTSPOT_CREATE,
            Permission.PUSH_SEND,
            Permission.SOURCES_MANAGE,
        }
    ),
    Role.VIEWER: frozenset({Permission.DASHBOARD_VIEW}),
}


def permissions_for(role: Role) -> frozenset[Permission]:
    return ROLE_PERMISSIONS[role]
