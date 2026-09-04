//! Contract tests for durable product and architecture documentation.

use std::{fs, path::PathBuf, process::Command};

const GOVERNING_ADRS: [&str; 10] = [
    "0001-product-boundary.md",
    "0002-space-fingerprint.md",
    "0003-directed-adapters.md",
    "0004-algorithm-portfolio.md",
    "0005-dual-index-native-backfill.md",
    "0006-rust-compute-plane.md",
    "0007-confidence-abstention.md",
    "0008-provider-neutral-ports.md",
    "0009-provenance-security.md",
    "0010-release-gates.md",
];

fn workspace_root() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .and_then(std::path::Path::parent)
        .map(std::path::Path::to_path_buf)
        .unwrap_or_else(|| panic!("crate must remain under the workspace root"))
}

fn read_document(relative_path: &str) -> String {
    let path = workspace_root().join(relative_path);
    fs::read_to_string(&path)
        .unwrap_or_else(|error| panic!("failed to read {}: {error}", path.display()))
}

#[test]
fn ci_uses_committed_lockfile_for_reproducible_dependency_resolution() {
    let root = workspace_root();
    let tracked = Command::new("git")
        .args(["ls-files", "--error-unmatch", "Cargo.lock"])
        .current_dir(&root)
        .output()
        .unwrap_or_else(|error| panic!("failed to inspect tracked files: {error}"));

    if !tracked.status.success() {
        let generated = fs::read_to_string(root.join("Cargo.lock"))
            .unwrap_or_else(|error| format!("<failed to read generated Cargo.lock: {error}>"));
        panic!("Cargo.lock must be committed; hosted Cargo generated:\n{generated}");
    }

    let ci = read_document(".github/workflows/ci.yml");
    assert!(
        ci.contains("run: cargo test --workspace --locked"),
        "stable workspace tests must use the committed lockfile"
    );
    assert!(
        ci.contains(
            "cargo +nightly-2026-08-01 llvm-cov\n          --workspace\n          --locked\n"
        ),
        "coverage must use the committed lockfile"
    );
}

#[test]
fn ci_only_cancels_superseded_ready_pr_runs() {
    let ci = read_document(".github/workflows/ci.yml");

    assert!(ci.contains("ready_for_review, converted_to_draft, closed"));
    assert!(ci.contains("${{ github.workflow }}-${{ github.repository }}-"));
    assert!(ci.contains("cancel-in-progress: ${{ github.event_name == 'pull_request' }}"));
    assert!(ci.contains("github.event.pull_request.draft == false"));
    assert!(ci.contains("github.event.action != 'closed'"));
}

#[test]
fn canonical_product_architecture_documents_exist() {
    let required = [
        "docs/PRD.md",
        "docs/TRD.md",
        "ARCHITECTURE.md",
        "docs/UML.md",
        "docs/ERD.md",
        "docs/API_CONTRACT.md",
        "docs/SECURITY.md",
        "docs/THREAT_MODEL.md",
        "docs/TEST_STRATEGY.md",
        "docs/OPERABILITY.md",
        "docs/TRACEABILITY.md",
        "docs/DOCUMENTATION_FITNESS.md",
        "docs/product-technical-gap-baseline.md",
        "docs/adr/README.md",
    ];

    let missing: Vec<&str> = required
        .into_iter()
        .filter(|relative_path| !workspace_root().join(relative_path).is_file())
        .collect();

    assert!(missing.is_empty(), "missing canonical documentation: {missing:?}");
}

#[test]
fn m1_postgres_erd_marks_current_and_planned_persistence_boundaries() {
    let erd = read_document("docs/ERD.md");
    assert!(
        erd.contains("<!-- status:present-current -->"),
        "ERD must expose a stable marker for the executable current persistence slice"
    );
    assert!(
        erd.contains("<!-- status:planned -->"),
        "ERD must expose a stable marker for the broader planned persistence target"
    );
    for required_object in ["tenant_space_registry", "space_registration_audit"] {
        assert!(
            erd.contains(required_object),
            "ERD is missing current persistence object: {required_object}"
        );
    }
}

#[test]
fn traceability_uses_stable_maturity_markers() {
    let traceability = read_document("docs/TRACEABILITY.md");
    assert!(
        traceability.contains("<!-- status:active-pr-implemented -->"),
        "traceability must mark active-PR implementation with a stable status marker"
    );
    assert!(
        traceability.contains("<!-- status:planned -->"),
        "traceability must mark future capabilities with a stable planned marker"
    );
    for required_capability in ["PostgreSQL tenant RLS/audit", "dual-index migration"] {
        assert!(
            traceability.contains(required_capability),
            "traceability is missing capability: {required_capability}"
        );
    }
}

#[test]
fn documentation_fitness_exposes_stable_status_vocabulary() {
    let fitness = read_document("docs/DOCUMENTATION_FITNESS.md");
    for status_marker in [
        "<!-- status:present-current -->",
        "<!-- status:partial -->",
        "<!-- status:planned -->",
    ] {
        assert!(
            fitness.contains(status_marker),
            "documentation fitness is missing stable marker: {status_marker}"
        );
    }
    assert!(fitness.contains(
        "does not make a deployable API or the full durable PostgreSQL control plane as-built"
    ));
}

#[test]
fn adr_index_contains_all_governing_decisions() {
    let index = read_document("docs/adr/README.md");
    for adr in GOVERNING_ADRS {
        assert!(index.contains(adr), "ADR index is missing {adr}");
    }
}

#[test]
fn governing_adrs_are_decision_complete() {
    let required_sections = [
        "## Context",
        "## Decision drivers",
        "## Alternatives considered",
        "## Decision",
        "## Consequences",
        "## Failure and recovery",
        "## Security and governance impact",
        "## Verification and acceptance evidence",
        "## Migration and rollback",
        "## Supersession",
    ];

    for adr in GOVERNING_ADRS {
        let relative_path = format!("docs/adr/{adr}");
        let document = read_document(&relative_path);
        for section in required_sections {
            assert!(
                document.contains(section),
                "{relative_path} is missing required ADR section {section}"
            );
        }
    }
}
