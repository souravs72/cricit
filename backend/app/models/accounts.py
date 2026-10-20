"""App users, devices, bookmarks, admins, sessions and the audit log."""

import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import Boolean, DateTime, ForeignKey, Index, Integer, String, Text, UniqueConstraint
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, IdMixin, TimestampMixin


class User(IdMixin, TimestampMixin, Base):
    __tablename__ = "users"

    phone: Mapped[str] = mapped_column(String(20), unique=True)
    firebase_uid: Mapped[str] = mapped_column(String(128), unique=True)
    name: Mapped[str | None] = mapped_column(String(20))
    bio: Mapped[str | None] = mapped_column(String(120))
    avatar_url: Mapped[str | None] = mapped_column(String(500))
    language: Mapped[str] = mapped_column(String(2), default="en")
    prefs: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict)
    last_seen_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class Device(IdMixin, TimestampMixin, Base):
    __tablename__ = "devices"

    user_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("users.id", ondelete="SET NULL"))
    fcm_token: Mapped[str] = mapped_column(String(300), unique=True)
    platform: Mapped[str] = mapped_column(String(10))
    app_version: Mapped[str] = mapped_column(String(20))


class Bookmark(IdMixin, TimestampMixin, Base):
    __tablename__ = "bookmarks"
    __table_args__ = (UniqueConstraint("user_id", "post_id"),)

    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    post_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("posts.id", ondelete="CASCADE"))


class Admin(IdMixin, TimestampMixin, Base):
    __tablename__ = "admins"

    email: Mapped[str] = mapped_column(String(254), unique=True)
    name: Mapped[str] = mapped_column(String(80))
    password_hash: Mapped[str | None] = mapped_column(String(200))  # null until invite accepted
    role: Mapped[str] = mapped_column(String(10))  # owner | editor | viewer
    totp_secret: Mapped[str | None] = mapped_column(String(64))  # encrypt at rest in T06
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    failed_logins: Mapped[int] = mapped_column(Integer, default=0)
    locked_until: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    invite_token_hash: Mapped[str | None] = mapped_column(String(64))
    invite_expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class AdminRecoveryCode(IdMixin, Base):
    __tablename__ = "admin_recovery_codes"

    admin_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("admins.id", ondelete="CASCADE"))
    code_hash: Mapped[str] = mapped_column(String(64))
    used_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class Session(IdMixin, TimestampMixin, Base):
    """A login on one device. Refresh tokens rotate within a family; reuse revokes the family."""

    __tablename__ = "sessions"
    __table_args__ = (Index("ix_sessions_principal", "principal_type", "principal_id"),)

    principal_type: Mapped[str] = mapped_column(String(5))  # user | admin
    principal_id: Mapped[uuid.UUID] = mapped_column()
    family_id: Mapped[uuid.UUID] = mapped_column(index=True)
    refresh_hash: Mapped[str] = mapped_column(String(64), unique=True)
    previous_hash: Mapped[str | None] = mapped_column(String(64), index=True)
    device_id: Mapped[str | None] = mapped_column(String(100))
    user_agent: Mapped[str | None] = mapped_column(String(300))
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    absolute_expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    revoked_reason: Mapped[str | None] = mapped_column(String(40))


class AuditLog(IdMixin, Base):
    __tablename__ = "audit_log"

    admin_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("admins.id", ondelete="SET NULL"))
    action: Mapped[str] = mapped_column(String(60))
    entity: Mapped[str] = mapped_column(String(40))
    entity_id: Mapped[str | None] = mapped_column(String(64))
    diff: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict)
    ip: Mapped[str | None] = mapped_column(String(45))
    ts: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    note: Mapped[str | None] = mapped_column(Text)
