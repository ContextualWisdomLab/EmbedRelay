# ADR-0007: Make abstention a first-class production outcome

**Status:** Accepted  
**Date:** 2026-08-09

## Context

An adapter can look adequate on average while failing on OOD queries, languages, domains, or sparse neighborhoods. Always returning a translated vector converts uncertainty into silent retrieval corruption.

## Decision

Every production translation is evaluated by a versioned confidence/policy gate. Low-confidence, OOD, authorization, or incompatible-space cases return an explicit abstention reason and invoke a defined fallback rather than forcing translation.

## Consequences

Calibration and abstention curves are release evidence. APIs and metrics distinguish translated success from abstention/fallback. Native re-embedding, source-index retrieval, dual search, or operator review are explicit fallback paths.