//! Contract tests for durable product and architecture documentation.

use std::{fs, path::PathBuf};

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
        "docs/adr/README.md",
    ];

    let missing: Vec<&str> = required
        .into_iter()
        .filter(|relative_path| !workspace_root().join(relative_path).is_file())
        .collect();

    assert!(missing.is_empty(), "missing canonical documentation: {missing:?}");
}

#[test]
fn conceptual_erd_does_not_claim_postgres_is_implemented() {
    let erd = read_document("docs/ERD.md");
    assert!(erd.contains("Current PR #1 persists none of these tables yet"));
    assert!(erd.contains("not implemented"));
    assert!(erd.contains("Planned PostgreSQL control-plane ERD"));
}

#[test]
fn traceability_keeps_planned_migration_components_planned() {
    let traceability = read_document("docs/TRACEABILITY.md");
    assert!(traceability.contains("directional role-specific adapters"));
    assert!(traceability.contains("dual-index migration"));
    assert!(traceability.contains("planned, not current"));
}

#[test]
fn documentation_fitness_exposes_conversation_planning_gaps_without_overclaiming() {
    let fitness = read_document("docs/DOCUMENTATION_FITNESS.md");
    for required_claim in [
        "Evaluation protocol | **PARTIAL**",
        "Research and standards traceability | **PARTIAL**",
        "Machine-readable API and schema artifacts | **PLANNED**",
        "Physical PostgreSQL ERD | **NOT-APPLICABLE**",
        "Data model | **PRESENT-CURRENT**",
        "Migration runbook | **PRESENT-CURRENT**",
    ] {
        assert!(
            fitness.contains(required_claim),
            "documentation fitness is missing required claim: {required_claim}"
        );
    }
    assert!(fitness.contains("does not make a deployable API or durable PostgreSQL control plane as-built"));
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
