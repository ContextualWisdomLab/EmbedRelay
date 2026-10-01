"""Behavioral regression tests for the exact-production-coverage CI gate."""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import textwrap
import unittest
from pathlib import Path
from typing import Any


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
WORKFLOW_PATH = REPOSITORY_ROOT / ".github" / "workflows" / "ci.yml"
REQUIRED_METRICS = ("lines", "regions", "functions", "branches")


def _coverage_gate_script() -> str:
    """Extract the Python program executed by the production coverage workflow step."""

    workflow = WORKFLOW_PATH.read_text(encoding="utf-8")
    step_start = workflow.index("      - name: Require exact production coverage")
    script_start = workflow.index("          import json\n", step_start)
    script_end = workflow.index("\n          PY", script_start)
    return textwrap.dedent(workflow[script_start:script_end])


def _coverage_report(count: Any, covered: Any) -> dict[str, Any]:
    """Build the LLVM summary shape consumed by the workflow gate."""

    return {
        "data": [
            {
                "totals": {
                    metric: {"count": count, "covered": covered}
                    for metric in REQUIRED_METRICS
                }
            }
        ]
    }


def _run_coverage_gate(report: dict[str, Any]) -> subprocess.CompletedProcess[str]:
    """Execute the checked-in gate against one isolated coverage summary."""

    with tempfile.TemporaryDirectory() as directory:
        Path(directory, "coverage-summary.json").write_text(
            json.dumps(report), encoding="utf-8"
        )
        return subprocess.run(
            [sys.executable, "-c", _coverage_gate_script()],
            cwd=directory,
            check=False,
            capture_output=True,
            text=True,
        )


class ExactProductionCoverageGateTests(unittest.TestCase):
    """Keep exact coverage both complete and non-vacuous."""

    def test_accepts_complete_nonzero_integer_summary(self) -> None:
        """Accept exact coverage only when LLVM reports real covered items."""

        result = _run_coverage_gate(_coverage_report(3, 3))

        self.assertEqual(result.returncode, 0, result.stderr)

    def test_rejects_incomplete_summary(self) -> None:
        """Reject an ordinary uncovered production item."""

        result = _run_coverage_gate(_coverage_report(3, 2))

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("2/3 covered", result.stderr)

    def test_rejects_missing_metric(self) -> None:
        """Reject a report that omits one required LLVM metric."""

        report = _coverage_report(3, 3)
        del report["data"][0]["totals"]["branches"]
        result = _run_coverage_gate(report)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("branches: metric absent", result.stderr)

    def test_rejects_vacuous_or_non_integer_summaries(self) -> None:
        """Reject coercible values that could counterfeit exact coverage."""

        invalid_values = (
            (0, 0),
            (-1, -1),
            (True, True),
            (1.2, 1.9),
            (3, -1),
            (3, 4),
        )

        for count, covered in invalid_values:
            with self.subTest(count=count, covered=covered):
                result = _run_coverage_gate(_coverage_report(count, covered))
                self.assertNotEqual(result.returncode, 0)


if __name__ == "__main__":
    unittest.main()
