# ADR-0005: Use dual-index transition and target-native backfill

**Status:** Accepted  
**Date:** 2026-08-09

## Context

Immediate replacement of a large legacy index creates availability and rollback risk. Keeping translated vectors forever creates unbounded fidelity debt.

## Decision

Migration uses bounded source/target index coexistence with explicit routing/fusion, canary/progressive cutover, rollback windows, and prioritized native target backfill. Raw scores from incompatible spaces are not averaged; default combination is rank-level fusion or separately evaluated reranking.

## Consequences

Source data/index remains available until cutover evidence and rollback policy permit retirement. Migration progress includes vector origin and native-backfill completeness.