from pydantic import BaseModel, EmailStr, Field


class FirebaseExchangeIn(BaseModel):
    id_token: str = Field(min_length=20)
    device_id: str = Field(min_length=8, max_length=100)


class RefreshIn(BaseModel):
    refresh_token: str = Field(min_length=20)


class TokenPair(BaseModel):
    access_token: str
    refresh_token: str
    expires_in: int
    token_type: str = "bearer"  # noqa: S105


class AdminLoginIn(BaseModel):
    email: EmailStr
    password: str = Field(min_length=12, max_length=200)


class AdminTotpIn(BaseModel):
    challenge_id: str
    code: str = Field(pattern=r"^(\d{6}|[0-9a-f]{6}-[0-9a-f]{6})$")  # TOTP or recovery code


class AdminChallenge(BaseModel):
    challenge_id: str
    method: str = "totp"
