"""Import every model so Alembic sees the full metadata."""

from app.models.accounts import Admin, AdminRecoveryCode, AuditLog, Bookmark, Device, Session, User
from app.models.ads import AdCampaign, AdStatsDaily, AiJob
from app.models.base import Base
from app.models.content import NxtspotSubmission, Post, PostSource, PostStatsDaily, Source

__all__ = [
    "AdCampaign",
    "AdStatsDaily",
    "Admin",
    "AdminRecoveryCode",
    "AiJob",
    "AuditLog",
    "Base",
    "Bookmark",
    "Device",
    "NxtspotSubmission",
    "Post",
    "PostSource",
    "PostStatsDaily",
    "Session",
    "Source",
    "User",
]
