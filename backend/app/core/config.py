"""Application settings, read once from the environment.

The app refuses to start when a required value is missing or unsafe in production.
"""

from functools import lru_cache
from typing import Literal

from pydantic import Field, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    env: Literal["local", "test", "staging", "production"] = "local"
    app_name: str = "CRICIT API"
    log_level: str = "INFO"

    database_url: str = "postgresql+asyncpg://cricit:cricit@localhost:5432/cricit"
    redis_url: str = "redis://localhost:6379/0"

    # ES256 signing. Private key PEM for the current key; public keys as "kid=PEM" pairs
    # separated by "||" so old keys keep verifying during rotation.
    jwt_private_key: str = ""
    jwt_key_id: str = "k1"
    jwt_public_keys: str = ""
    jwt_issuer: str = "cricit"
    user_access_ttl_s: int = 15 * 60
    admin_access_ttl_s: int = 10 * 60
    user_session_sliding_days: int = 30
    user_session_absolute_days: int = 90
    admin_session_idle_min: int = 30
    admin_session_absolute_h: int = 12

    firebase_project_id: str = ""
    firebase_credentials_json: str = ""  # base64 service-account JSON

    llm_provider: str = "anthropic"
    llm_api_key: str = ""
    llm_model: str = ""

    youtube_api_key: str = ""

    r2_account_id: str = ""
    r2_access_key_id: str = ""
    r2_secret_access_key: str = ""
    r2_bucket: str = "cricit-media"
    cdn_base_url: str = ""

    admin_origin: str = "http://localhost:3000"
    sentry_dsn: str = ""

    feed_page_size: int = Field(default=20, ge=5, le=50)

    @model_validator(mode="after")
    def _require_secrets_outside_local(self) -> "Settings":
        if self.env in {"staging", "production"}:
            missing = [
                name
                for name in (
                    "jwt_private_key",
                    "jwt_public_keys",
                    "firebase_project_id",
                    "firebase_credentials_json",
                    "llm_api_key",
                    "sentry_dsn",
                )
                if not getattr(self, name)
            ]
            if missing:
                raise ValueError(f"Missing required settings for {self.env}: {', '.join(missing)}")
            if "cricit:cricit@" in self.database_url:
                raise ValueError("Default database password is not allowed outside local/test")
        return self


@lru_cache
def get_settings() -> Settings:
    return Settings()
