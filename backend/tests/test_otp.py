import pytest

from app.services.otp import _MEMORY_OTP, send_otp


@pytest.mark.asyncio
async def test_send_otp_service():
    res = await send_otp("9876543210")
    assert res.success is True
    assert res.phone == "9876543210"
    assert "cricit-otp-9876543210" in res.channel_url
    assert "9876543210" in _MEMORY_OTP
    code, _ = _MEMORY_OTP["9876543210"]
    assert len(code) == 6
    assert code.isdigit()
