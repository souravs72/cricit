"""Provider-agnostic LLM interface. Ticket T13 adds the concrete provider adapter."""

from dataclasses import dataclass
from pathlib import Path
from typing import Any, Protocol

PROMPTS_DIR = Path(__file__).parent / "prompts"


@dataclass(frozen=True)
class LLMResult:
    data: dict[str, Any]
    model: str
    input_tokens: int
    output_tokens: int


class LLMClient(Protocol):
    async def complete_json(
        self, *, system: str, user: str, schema: dict[str, Any], max_tokens: int = 800
    ) -> LLMResult: ...


def load_prompt(name: str) -> tuple[str, str]:
    """Return (version, text) for a prompt file like 'summarize_v1'."""
    path = PROMPTS_DIR / f"{name}.md"
    return name, path.read_text(encoding="utf-8")


SUMMARY_SCHEMA: dict[str, Any] = {
    "type": "object",
    "required": [
        "headline",
        "summary",
        "category",
        "tags",
        "headline_hi",
        "summary_hi",
        "relevance",
    ],
    "properties": {
        "headline": {"type": "string", "maxLength": 80},
        "summary": {"type": "string"},
        "category": {"enum": ["domestic", "international", "grassroots"]},
        "tags": {"type": "array", "items": {"type": "string"}, "maxItems": 8},
        "headline_hi": {"type": "string"},
        "summary_hi": {"type": "string"},
        "relevance": {"type": "number", "minimum": 0, "maximum": 1},
    },
}
