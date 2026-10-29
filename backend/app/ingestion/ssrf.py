"""Block fetches to localhost, link-local and RFC1918 addresses (T09).

Callers: schemas.sources (create/patch), RssAdapter.fetch, sources.test_fetch.
"""

from __future__ import annotations

import ipaddress
import socket
from urllib.parse import urlsplit

from app.core.errors import ValidationFailed

_BLOCKED_HOSTS = {"localhost", "metadata.google.internal", "metadata"}


def _blocked_ip(ip: ipaddress.IPv4Address | ipaddress.IPv6Address) -> bool:
    """Treat IPv4-mapped IPv6 (::ffff:127.0.0.1) as the inner v4 address."""
    mapped = getattr(ip, "ipv4_mapped", None)
    if mapped is not None:
        ip = mapped
    return bool(
        ip.is_private
        or ip.is_loopback
        or ip.is_link_local
        or ip.is_multicast
        or ip.is_reserved
        or ip.is_unspecified
    )


def assert_public_http_url(url: str, *, field: str = "url") -> str:
    """Reject non-http(s) and literal private/loopback hosts. Does not resolve DNS."""
    raw = (url or "").strip()
    parts = urlsplit(raw)
    if parts.scheme not in ("http", "https"):
        raise ValidationFailed("URL must be http or https", field=field)
    host = (parts.hostname or "").lower()
    if not host:
        raise ValidationFailed("URL is missing a host", field=field)
    if host in _BLOCKED_HOSTS or host.endswith(".local") or host.endswith(".localhost"):
        raise ValidationFailed("That host is not allowed", field=field)
    if host.endswith(".internal"):
        raise ValidationFailed("That host is not allowed", field=field)
    try:
        ip = ipaddress.ip_address(host)
    except ValueError:
        return raw
    if _blocked_ip(ip):
        raise ValidationFailed("Private addresses are not allowed", field=field)
    return raw


def assert_safe_to_fetch(url: str, *, field: str = "feed_url") -> str:
    """Same as assert_public_http_url, then resolve and reject private A/AAAA records."""
    raw = assert_public_http_url(url, field=field)
    host = urlsplit(raw).hostname
    if host is None:
        raise ValidationFailed("URL is missing a host", field=field)
    try:
        infos = socket.getaddrinfo(host, None, type=socket.SOCK_STREAM)
    except OSError as exc:
        raise ValidationFailed("Could not resolve that host", field=field) from exc
    for info in infos:
        addr = info[4][0]
        if _blocked_ip(ipaddress.ip_address(addr)):
            raise ValidationFailed("Private addresses are not allowed", field=field)
    return raw
