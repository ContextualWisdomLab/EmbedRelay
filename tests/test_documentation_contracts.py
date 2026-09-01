"""Regression tests for machine-readable EmbedRelay documentation contracts."""

from __future__ import annotations

import json
import re
import unittest
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
SCHEMA_PATH = REPOSITORY_ROOT / "docs" / "contracts" / "conversion-response-v1.schema.json"
SPACE_PREFIX = "urn:cwl:embed-space:v1:sha256:"
VALID_DIGEST = "a" * 64
VALID_SPACE_ID = f"{SPACE_PREFIX}{VALID_DIGEST}"
CANONICAL_BASELINES = (
    "AGENTS.md",
    "CLAUDE.md",
    "ARCHITECTURE.md",
    "CHANGELOG.md",
    "docs/product-technical-gap-baseline.md",
)


def _matches_string_definition(definition: dict[str, object], value: str) -> bool:
    """Apply the string constraints used by the public identifier definitions."""

    if definition.get("type") != "string":
        return False
    min_length = definition.get("minLength")
    max_length = definition.get("maxLength")
    if isinstance(min_length, int) and len(value) < min_length:
        return False
    if isinstance(max_length, int) and len(value) > max_length:
        return False
    pattern = definition.get("pattern")
    if isinstance(pattern, str) and re.search(pattern, value) is None:
        return False
    return True


class ConversionResponseSchemaTests(unittest.TestCase):
    """Keep identifier and digest boundaries exact rather than anchor-dependent."""

    @classmethod
    def setUpClass(cls) -> None:
        """Load the checked-in Draft 2020-12 payload schema once."""

        cls.schema = json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))

    def test_space_identifier_is_exactly_94_characters(self) -> None:
        """Accept the canonical space ID and reject line-terminated variants."""

        definition = self.schema["$defs"]["spaceId"]
        self.assertEqual(definition["minLength"], 94)
        self.assertEqual(definition["maxLength"], 94)
        self.assertTrue(_matches_string_definition(definition, VALID_SPACE_ID))
        self.assertFalse(_matches_string_definition(definition, f"{VALID_SPACE_ID}\n"))
        self.assertFalse(_matches_string_definition(definition, f"{VALID_SPACE_ID}\r\n"))

    def test_sha256_digest_is_exactly_64_lowercase_hex_characters(self) -> None:
        """Accept the canonical digest and reject LF/CRLF-terminated digests."""

        definition = self.schema["$defs"]["sha256"]
        self.assertEqual(definition["minLength"], 64)
        self.assertEqual(definition["maxLength"], 64)
        self.assertTrue(_matches_string_definition(definition, VALID_DIGEST))
        self.assertFalse(_matches_string_definition(definition, f"{VALID_DIGEST}\n"))
        self.assertFalse(_matches_string_definition(definition, f"{VALID_DIGEST}\r\n"))
        self.assertFalse(_matches_string_definition(definition, "A" * 64))


class CanonicalRepositoryBaselineTests(unittest.TestCase):
    """Keep commercialization and engineering authority in durable repository files."""

    def test_required_canonical_baselines_exist_and_are_nonempty(self) -> None:
        """Prevent canonical product/engineering baselines from disappearing silently."""

        for relative_path in CANONICAL_BASELINES:
            with self.subTest(path=relative_path):
                path = REPOSITORY_ROOT / relative_path
                self.assertTrue(path.is_file(), f"missing canonical baseline: {relative_path}")
                self.assertTrue(path.read_text(encoding="utf-8").strip(), f"empty canonical baseline: {relative_path}")

    def test_documentation_index_links_canonical_product_authority(self) -> None:
        """Make the canonical architecture and commercialization ledger discoverable."""

        index = (REPOSITORY_ROOT / "docs" / "index.md").read_text(encoding="utf-8")
        self.assertIn("../ARCHITECTURE.md", index)
        self.assertIn("product-technical-gap-baseline.md", index)
        self.assertIn("../AGENTS.md", index)
        self.assertIn("../CHANGELOG.md", index)

    def test_agent_rules_keep_rust_numerics_and_fail_closed_thresholds(self) -> None:
        """Guard the production numerical-language and evidence-derived threshold contracts."""

        agents = (REPOSITORY_ROOT / "AGENTS.md").read_text(encoding="utf-8")
        self.assertIn("Mathematical/vector/linear-algebra/token-size production computation is Rust-owned", agents)
        self.assertIn("Do not introduce undocumented rule-of-thumb constants", agents)
        self.assertIn("two-or-more-word `snake_case`", agents)


if __name__ == "__main__":
    unittest.main()
