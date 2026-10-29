"""T09: outbound source URLs must be http(s) on a public host.

Callers: pytest (`make check-backend`). Module: app.ingestion.ssrf.
User: "Check what is tobe built now into this - build it"
"""

import pytest

from app.core.errors import ValidationFailed
from app.ingestion.ssrf import assert_public_http_url, assert_safe_to_fetch


@pytest.mark.parametrize(
    "url",
    [
        "http://127.0.0.1/rss.xml",
        "http://localhost/rss.xml",
        "http://[::1]/rss.xml",
        "http://[::ffff:127.0.0.1]/rss.xml",
        "http://10.0.0.8/feed",
        "http://192.168.1.9/feed",
        "http://169.254.169.254/latest/meta-data/",
        "http://0.0.0.0/feed",
        "http://cricit.local/feed",
        "file:///etc/passwd",
        "ftp://example.com/feed",
        "https://",
    ],
)
def test_private_and_non_http_urls_are_rejected(url: str) -> None:
    with pytest.raises(ValidationFailed):
        assert_public_http_url(url, field="feed_url")


def test_public_https_feed_is_allowed() -> None:
    url = "https://www.espncricinfo.com/rss/content/story/feeds/0.xml"
    assert assert_public_http_url(url) == url


def test_safe_to_fetch_still_blocks_loopback() -> None:
    with pytest.raises(ValidationFailed):
        assert_safe_to_fetch("http://127.0.0.1/rss.xml")
