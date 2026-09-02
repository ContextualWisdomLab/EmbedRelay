"""Fail-closed guardrails for the pre-release EmbedRelay response schema and CI range."""

from __future__ import annotations

import json
import math
import os
import re
import subprocess
import unittest
from copy import deepcopy
from pathlib import Path
from typing import Any


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
SCHEMA_PATH = REPOSITORY_ROOT / "docs" / "contracts" / "conversion-response-v1.schema.json"
SPACE_PREFIX = "urn:cwl:embed-space:v1:sha256:"
VECTOR_SCHEMA_PREFIX = "urn:cwl:embed-vector-schema:v1:sha256:"
VALID_SPACE_ID = f"{SPACE_PREFIX}{'a' * 64}"
VALID_TARGET_SPACE_ID = f"{SPACE_PREFIX}{'b' * 64}"
VALID_VECTOR_SCHEMA_ID = f"{VECTOR_SCHEMA_PREFIX}{'c' * 64}"
VALID_DIGEST = "d" * 64
SUPPORTED_SCHEMA_KEYWORDS = {
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
    "maxItems",
    "items",
    "required",
    "properties",
    "additionalProperties",
}


def _assert_supported_keywords(schema: dict[str, Any], path: str = "$") -> None:
    """Reject every schema keyword the dependency-free verifier does not understand."""

    unknown = sorted(set(schema) - SUPPORTED_SCHEMA_KEYWORDS)
    if unknown:
        raise AssertionError(f"{path}: unsupported JSON Schema keywords: {unknown}")
    defs = schema.get("$defs")
    if isinstance(defs, dict):
        for name, child in defs.items():
            if not isinstance(child, dict):
                raise AssertionError(f"{path}.$defs.{name}: schema must be an object")
            _assert_supported_keywords(child, f"{path}.$defs.{name}")
    properties = schema.get("properties")
    if isinstance(properties, dict):
        for name, child in properties.items():
            if not isinstance(child, dict):
                raise AssertionError(f"{path}.properties.{name}: schema must be an object")
            _assert_supported_keywords(child, f"{path}.properties.{name}")
    alternatives = schema.get("oneOf")
    if isinstance(alternatives, list):
        for index, child in enumerate(alternatives):
            if not isinstance(child, dict):
                raise AssertionError(f"{path}.oneOf[{index}]: schema must be an object")
            _assert_supported_keywords(child, f"{path}.oneOf[{index}]")
    items = schema.get("items")
    if isinstance(items, dict):
        _assert_supported_keywords(items, f"{path}.items")


def _resolve_local_ref(root: dict[str, Any], reference: str) -> dict[str, Any]:
    if not reference.startswith("#/"):
        raise AssertionError(f"unsupported non-local ref: {reference}")
    value: Any = root
    for raw_part in reference[2:].split("/"):
        part = raw_part.replace("~1", "/").replace("~0", "~")
        value = value[part]
    if not isinstance(value, dict):
        raise AssertionError(f"ref does not resolve to a schema object: {reference}")
    return value


def _type_matches(expected: str, value: Any) -> bool:
    if expected == "object":
        return isinstance(value, dict)
    if expected == "array":
        return isinstance(value, list)
    if expected == "string":
        return isinstance(value, str)
    if expected == "number":
        return (
            isinstance(value, (int, float))
            and not isinstance(value, bool)
            and math.isfinite(float(value))
        )
    if expected == "integer":
        return isinstance(value, int) and not isinstance(value, bool)
    if expected == "null":
        return value is None
    if expected == "boolean":
        return isinstance(value, bool)
    raise AssertionError(f"unsupported schema type: {expected}")


def _schema_errors(
    root: dict[str, Any], schema: dict[str, Any], value: Any, path: str = "$"
) -> list[str]:
    """Validate the closed subset after first proving every keyword is supported."""

    _assert_supported_keywords(schema, path)
    if "$ref" in schema:
        return _schema_errors(root, _resolve_local_ref(root, schema["$ref"]), value, path)
    if "oneOf" in schema:
        matches = [
            candidate
            for candidate in schema["oneOf"]
            if not _schema_errors(root, candidate, value, path)
        ]
        return [] if len(matches) == 1 else [f"{path}: expected one oneOf match"]

    errors: list[str] = []
    expected_type = schema.get("type")
    if isinstance(expected_type, str) and not _type_matches(expected_type, value):
        return [f"{path}: expected {expected_type}"]
    if "const" in schema and value != schema["const"]:
        errors.append(f"{path}: const mismatch")
    if "enum" in schema and value not in schema["enum"]:
        errors.append(f"{path}: enum mismatch")

    if isinstance(value, str):
        if isinstance(schema.get("minLength"), int) and len(value) < schema["minLength"]:
            errors.append(f"{path}: shorter than minLength")
        if isinstance(schema.get("maxLength"), int) and len(value) > schema["maxLength"]:
            errors.append(f"{path}: longer than maxLength")
        pattern = schema.get("pattern")
        if isinstance(pattern, str) and re.search(pattern, value) is None:
            errors.append(f"{path}: pattern mismatch")

    if isinstance(value, list):
        if isinstance(schema.get("minItems"), int) and len(value) < schema["minItems"]:
            errors.append(f"{path}: fewer than minItems")
        if isinstance(schema.get("maxItems"), int) and len(value) > schema["maxItems"]:
            errors.append(f"{path}: more than maxItems")
        item_schema = schema.get("items")
        if isinstance(item_schema, dict):
            for index, item in enumerate(value):
                errors.extend(_schema_errors(root, item_schema, item, f"{path}[{index}]"))

    if isinstance(value, dict):
        required = schema.get("required")
        if isinstance(required, list):
            for key in required:
                if key not in value:
                    errors.append(f"{path}: missing {key}")
        properties = schema.get("properties")
        if isinstance(properties, dict):
            if schema.get("additionalProperties") is False:
                for key in value:
                    if key not in properties:
                        errors.append(f"{path}: additional property {key}")
            for key, child in properties.items():
                if key in value and isinstance(child, dict):
                    errors.extend(_schema_errors(root, child, value[key], f"{path}.{key}"))
    return errors


def _target_bound_schema(
    root: dict[str, Any], *, target_space_id: str, vector_schema_id: str, dimension: int
) -> dict[str, Any]:
    """Materialize the release-specific converted schema from immutable space identity evidence."""

    if dimension <= 0:
        raise ValueError("dimension must be positive")
    bound = deepcopy(root)
    converted = bound["$defs"]["converted"]
    converted["properties"]["target_space_id"] = {"const": target_space_id}
    converted["properties"]["target_vector_schema_id"] = {"const": vector_schema_id}
    vector = converted["properties"]["vector"]
    vector["minItems"] = dimension
    vector["maxItems"] = dimension
    return bound


def _valid_converted() -> dict[str, Any]:
    return {
        "schema_version": 1,
        "request_id": "request-001",
        "status": "converted",
        "source_space_id": VALID_SPACE_ID,
        "target_space_id": VALID_TARGET_SPACE_ID,
        "target_vector_schema_id": VALID_VECTOR_SCHEMA_ID,
        "vector_origin": "translated",
        "adapter_artifact": {
            "adapter_id": "adapter-v1",
            "sha256": VALID_DIGEST,
            "policy_id": "policy-v1",
            "decision_receipt_id": "decision-001",
        },
        "vector": [0.25, -0.5, 0.75],
        "abstention": None,
    }


class SchemaGuardrailTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.schema = json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))
        _assert_supported_keywords(cls.schema)

    def test_unknown_schema_keyword_fails_closed(self) -> None:
        mutated = deepcopy(self.schema)
        mutated["$defs"]["converted"]["properties"]["vector"]["minContains"] = 1
        with self.assertRaisesRegex(AssertionError, "unsupported JSON Schema keywords"):
            _assert_supported_keywords(mutated)

    def test_vector_schema_identifier_is_exact_and_immutable(self) -> None:
        definition = self.schema["$defs"]["vectorSchemaId"]
        self.assertEqual(definition["minLength"], 102)
        self.assertEqual(definition["maxLength"], 102)
        self.assertIsNotNone(re.search(definition["pattern"], VALID_VECTOR_SCHEMA_ID))
        self.assertIsNone(re.search(definition["pattern"], f"{VALID_VECTOR_SCHEMA_ID}\n"))

    def test_target_specific_release_schema_binds_identity_and_exact_dimension(self) -> None:
        bound = _target_bound_schema(
            self.schema,
            target_space_id=VALID_TARGET_SPACE_ID,
            vector_schema_id=VALID_VECTOR_SCHEMA_ID,
            dimension=3,
        )
        converted_schema = bound["$defs"]["converted"]
        value = _valid_converted()
        self.assertEqual(_schema_errors(bound, converted_schema, value), [])

        wrong_length = deepcopy(value)
        wrong_length["vector"] = [0.25, -0.5]
        self.assertTrue(_schema_errors(bound, converted_schema, wrong_length))

        wrong_target = deepcopy(value)
        wrong_target["target_space_id"] = VALID_SPACE_ID
        self.assertTrue(_schema_errors(bound, converted_schema, wrong_target))

    def test_non_finite_values_fail_schema_and_strict_json_serialization(self) -> None:
        bound = _target_bound_schema(
            self.schema,
            target_space_id=VALID_TARGET_SPACE_ID,
            vector_schema_id=VALID_VECTOR_SCHEMA_ID,
            dimension=3,
        )
        converted_schema = bound["$defs"]["converted"]
        for value in (math.nan, math.inf, -math.inf):
            payload = _valid_converted()
            payload["vector"][1] = value
            self.assertTrue(_schema_errors(bound, converted_schema, payload))
            with self.assertRaises(ValueError):
                json.dumps(payload, allow_nan=False)

    def test_current_ci_range_runs_git_diff_check_on_committed_changes(self) -> None:
        event = os.environ.get("EMBEDRELAY_DOCS_EVENT")
        base = os.environ.get("EMBEDRELAY_DOCS_BASE_SHA")
        if not event or not base:
            self.skipTest("exact CI event/base is supplied only by Documentation Quality")
        if set(base) == {"0"}:
            command = ["git", "show", "--check", "--format=", "HEAD"]
        elif event == "pull_request":
            command = ["git", "diff", "--check", f"{base}...HEAD"]
        else:
            command = ["git", "diff", "--check", base, "HEAD"]
        result = subprocess.run(
            command,
            cwd=REPOSITORY_ROOT,
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
