"""Regression tests for machine-readable EmbedRelay documentation contracts."""

from __future__ import annotations

import json
import math
import re
import unittest
from copy import deepcopy
from pathlib import Path
from typing import Any


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
SCHEMA_PATH = REPOSITORY_ROOT / "docs" / "contracts" / "conversion-response-v1.schema.json"
WORKFLOW_PATH = REPOSITORY_ROOT / ".github" / "workflows" / "docs-quality.yml"
SPACE_PREFIX = "urn:cwl:embed-space:v1:sha256:"
VECTOR_SCHEMA_PREFIX = "urn:cwl:embed-vector-schema:v1:sha256:"
VALID_DIGEST = "a" * 64
VALID_SPACE_ID = f"{SPACE_PREFIX}{VALID_DIGEST}"
VALID_VECTOR_SCHEMA_ID = f"{VECTOR_SCHEMA_PREFIX}{'c' * 64}"
SUPPORTED_VALIDATOR_KEYWORDS = {
    "$schema",
    "$id",
    "$defs",
    "$ref",
    "title",
    "description",
    "oneOf",
    "type",
    "const",
    "enum",
    "minLength",
    "maxLength",
    "pattern",
    "minItems",
    "items",
    "required",
    "properties",
    "additionalProperties",
}
CANONICAL_BASELINES = (
    "AGENTS.md",
    "CLAUDE.md",
    "ARCHITECTURE.md",
    "CHANGELOG.md",
    "SECURITY.md",
    "docs/PRD.md",
    "docs/TRD.md",
    "docs/UML.md",
    "docs/ERD.md",
    "docs/TEST_STRATEGY.md",
    "docs/OPERABILITY.md",
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


def _resolve_local_ref(root_schema: dict[str, Any], reference: str) -> dict[str, Any]:
    """Resolve the local JSON Pointer references used by the checked-in contract."""

    if not reference.startswith("#/"):
        raise AssertionError(f"unsupported non-local reference in dependency-free contract test: {reference}")
    value: Any = root_schema
    for raw_part in reference[2:].split("/"):
        part = raw_part.replace("~1", "/").replace("~0", "~")
        value = value[part]
    if not isinstance(value, dict):
        raise AssertionError(f"reference does not resolve to a schema object: {reference}")
    return value


def _type_matches(expected: str, value: Any) -> bool:
    """Implement the Draft 2020-12 primitive types used by this payload contract."""

    if expected == "object":
        return isinstance(value, dict)
    if expected == "array":
        return isinstance(value, list)
    if expected == "string":
        return isinstance(value, str)
    if expected == "number":
        if isinstance(value, bool) or not isinstance(value, (int, float)):
            return False
        return math.isfinite(value) if isinstance(value, float) else True
    if expected == "integer":
        return isinstance(value, int) and not isinstance(value, bool)
    if expected == "null":
        return value is None
    if expected == "boolean":
        return isinstance(value, bool)
    raise AssertionError(f"unsupported schema type in dependency-free contract test: {expected}")


def _schema_errors(root_schema: dict[str, Any], schema: dict[str, Any], value: Any, path: str = "$") -> list[str]:
    """Validate the finite JSON Schema subset used by conversion-response-v1."""

    unsupported = sorted(set(schema) - SUPPORTED_VALIDATOR_KEYWORDS)
    if unsupported:
        raise AssertionError(f"{path}: unsupported JSON Schema keywords: {unsupported}")

    if "$ref" in schema:
        return _schema_errors(root_schema, _resolve_local_ref(root_schema, schema["$ref"]), value, path)

    if "oneOf" in schema:
        alternatives = schema["oneOf"]
        matches = [candidate for candidate in alternatives if not _schema_errors(root_schema, candidate, value, path)]
        return [] if len(matches) == 1 else [f"{path}: expected exactly one oneOf match, got {len(matches)}"]

    errors: list[str] = []
    expected_type = schema.get("type")
    if isinstance(expected_type, str) and not _type_matches(expected_type, value):
        return [f"{path}: expected {expected_type}"]

    if "const" in schema and value != schema["const"]:
        errors.append(f"{path}: expected const {schema['const']!r}")
    if "enum" in schema and value not in schema["enum"]:
        errors.append(f"{path}: value is outside enum")

    if isinstance(value, str):
        min_length = schema.get("minLength")
        max_length = schema.get("maxLength")
        pattern = schema.get("pattern")
        if isinstance(min_length, int) and len(value) < min_length:
            errors.append(f"{path}: shorter than minLength")
        if isinstance(max_length, int) and len(value) > max_length:
            errors.append(f"{path}: longer than maxLength")
        if isinstance(pattern, str) and re.search(pattern, value) is None:
            errors.append(f"{path}: does not match pattern")

    if isinstance(value, list):
        min_items = schema.get("minItems")
        if isinstance(min_items, int) and len(value) < min_items:
            errors.append(f"{path}: fewer than minItems")
        item_schema = schema.get("items")
        if isinstance(item_schema, dict):
            for index, item in enumerate(value):
                errors.extend(_schema_errors(root_schema, item_schema, item, f"{path}[{index}]"))

    if isinstance(value, dict):
        required = schema.get("required", [])
        if isinstance(required, list):
            for key in required:
                if key not in value:
                    errors.append(f"{path}: missing required property {key}")
        properties = schema.get("properties", {})
        if isinstance(properties, dict):
            if schema.get("additionalProperties") is False:
                for key in value:
                    if key not in properties:
                        errors.append(f"{path}: additional property {key}")
            for key, property_schema in properties.items():
                if key in value and isinstance(property_schema, dict):
                    errors.extend(_schema_errors(root_schema, property_schema, value[key], f"{path}.{key}"))

    return errors


def _valid_adapter() -> dict[str, Any]:
    """Return one canonical adapter artifact fixture."""

    return {
        "adapter_id": "adapter-v1",
        "sha256": VALID_DIGEST,
        "policy_id": "policy-v1",
        "decision_receipt_id": "decision-001",
    }


def _valid_converted() -> dict[str, Any]:
    """Return a canonical converted response fixture."""

    return {
        "schema_version": 1,
        "request_id": "request-001",
        "status": "converted",
        "source_space_id": VALID_SPACE_ID,
        "target_space_id": f"{SPACE_PREFIX}{'b' * 64}",
        "target_vector_schema_id": VALID_VECTOR_SCHEMA_ID,
        "vector_origin": "translated",
        "adapter_artifact": _valid_adapter(),
        "vector": [0.25, -0.5, 0.75],
        "abstention": None,
    }


def _valid_abstained() -> dict[str, Any]:
    """Return a canonical abstained response fixture."""

    value = _valid_converted()
    value.pop("target_vector_schema_id")
    value.update(
        status="abstained",
        vector_origin=None,
        vector=None,
        abstention={"code": "out_of_distribution"},
    )
    return value


def _valid_error() -> dict[str, Any]:
    """Return a canonical error response fixture."""

    return {
        "schema_version": 1,
        "request_id": "request-001",
        "status": "error",
        "error": {"code": "invalid_request", "message": "invalid request"},
    }


class ConversionResponseSchemaTests(unittest.TestCase):
    """Keep the full conversion response union fail-closed and machine-readable."""

    @classmethod
    def setUpClass(cls) -> None:
        """Load the checked-in Draft 2020-12 payload schema once."""

        cls.schema = json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))

    def assertContractValid(self, value: Any) -> None:  # noqa: N802 - unittest naming convention
        """Assert that one payload satisfies the dependency-free contract validator."""

        self.assertEqual(_schema_errors(self.schema, self.schema, value), [])

    def assertContractInvalid(self, value: Any) -> None:  # noqa: N802 - unittest naming convention
        """Assert that one payload is rejected by the dependency-free contract validator."""

        self.assertTrue(_schema_errors(self.schema, self.schema, value), f"payload unexpectedly valid: {value!r}")

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

    def test_all_three_union_variants_have_valid_examples(self) -> None:
        """Prove converted, abstained and error are each independently accepted."""

        for value in (_valid_converted(), _valid_abstained(), _valid_error()):
            with self.subTest(status=value["status"]):
                self.assertContractValid(value)

    def test_missing_required_property_is_rejected(self) -> None:
        """Reject a payload that would otherwise resemble the converted variant."""

        value = _valid_converted()
        del value["request_id"]
        self.assertContractInvalid(value)

    def test_unknown_top_level_and_nested_properties_are_rejected(self) -> None:
        """Keep closed response and adapter objects closed in executable evidence."""

        top_level = _valid_converted()
        top_level["surprise"] = True
        self.assertContractInvalid(top_level)

        nested = _valid_converted()
        nested["adapter_artifact"]["surprise"] = True
        self.assertContractInvalid(nested)

    def test_malformed_vectors_are_rejected(self) -> None:
        """Reject empty, non-array, non-numeric, and non-finite converted vectors."""

        for vector in (
            [],
            "not-a-vector",
            [0.25, "bad"],
            [0.25, math.nan],
            [math.inf],
            [-math.inf],
        ):
            with self.subTest(vector=vector):
                value = _valid_converted()
                value["vector"] = vector
                self.assertContractInvalid(value)

    def test_huge_json_integer_does_not_abort_number_validation(self) -> None:
        """Treat an arbitrarily large JSON integer as a number without float overflow."""

        value = _valid_converted()
        value["vector"][1] = 10**10000
        self.assertContractValid(value)

    def test_cross_variant_fields_and_statuses_do_not_escape_one_of(self) -> None:
        """Reject hybrid or unknown union variants rather than choosing one permissively."""

        wrong_status = _valid_converted()
        wrong_status["status"] = "success"
        self.assertContractInvalid(wrong_status)

        hybrid_error = _valid_error()
        hybrid_error["source_space_id"] = VALID_SPACE_ID
        self.assertContractInvalid(hybrid_error)

        invalid_abstention = _valid_abstained()
        invalid_abstention["abstention"] = {"code": "guess_anyway"}
        self.assertContractInvalid(invalid_abstention)

    def test_unsupported_schema_keyword_fails_closed(self) -> None:
        """Never let a newly added schema constraint escape the local validator silently."""

        schema = deepcopy(self.schema)
        schema["$defs"]["converted"]["properties"]["vector"]["maxItems"] = 3
        with self.assertRaisesRegex(AssertionError, "unsupported JSON Schema keywords"):
            _schema_errors(schema, schema, _valid_converted())


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
        """Make product, engineering, diagrams, security, test and operability authority discoverable."""

        index = (REPOSITORY_ROOT / "docs" / "index.md").read_text(encoding="utf-8")
        for required_link in (
            "../ARCHITECTURE.md",
            "product-technical-gap-baseline.md",
            "../AGENTS.md",
            "../CHANGELOG.md",
            "../SECURITY.md",
            "PRD.md",
            "TRD.md",
            "UML.md",
            "ERD.md",
            "TEST_STRATEGY.md",
            "OPERABILITY.md",
        ):
            with self.subTest(link=required_link):
                self.assertIn(required_link, index)

    def test_agent_rules_keep_rust_numerics_and_fail_closed_thresholds(self) -> None:
        """Guard the production numerical-language and evidence-derived threshold contracts."""

        agents = (REPOSITORY_ROOT / "AGENTS.md").read_text(encoding="utf-8")
        self.assertIn("Mathematical/vector/linear-algebra/token-size production computation is Rust-owned", agents)
        self.assertIn("Do not introduce undocumented rule-of-thumb constants", agents)
        self.assertIn("two-or-more-word `snake_case`", agents)

    def test_product_and_technical_docs_reject_as_built_overclaim(self) -> None:
        """Keep pre-release requirements and target diagrams separate from as-built runtime claims."""

        prd = (REPOSITORY_ROOT / "docs" / "PRD.md").read_text(encoding="utf-8")
        trd = (REPOSITORY_ROOT / "docs" / "TRD.md").read_text(encoding="utf-8")
        uml = (REPOSITORY_ROOT / "docs" / "UML.md").read_text(encoding="utf-8")
        erd = (REPOSITORY_ROOT / "docs" / "ERD.md").read_text(encoding="utf-8")
        operability = (REPOSITORY_ROOT / "docs" / "OPERABILITY.md").read_text(encoding="utf-8")
        self.assertIn("pre-release", prd.lower())
        self.assertIn("not as-built runtime evidence", trd)
        self.assertIn("not as-built runtime evidence", uml)
        self.assertIn("no current database is claimed", erd.lower())
        self.assertIn("does not ship a network service", operability)

    def test_docs_quality_checks_committed_pr_and_push_ranges(self) -> None:
        """Require whitespace validation to inspect committed changes, not an empty worktree diff."""

        workflow = WORKFLOW_PATH.read_text(encoding="utf-8")
        self.assertIn("fetch-depth: 0", workflow)
        self.assertIn("github.event.pull_request.base.sha", workflow)
        self.assertIn("github.event.before", workflow)
        self.assertIn("tests/test_schema_guardrails.py", workflow)
        self.assertNotIn("run: git diff --check\n", workflow)


if __name__ == "__main__":
    unittest.main()
