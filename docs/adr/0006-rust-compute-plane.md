# ADR-0006: Keep production transformation arithmetic in Rust

**Status:** Accepted  
**Date:** 2026-08-09

## Context

Adapter fitting/evaluation is numerically sensitive and can become computationally heavy at enterprise scale. A single reference implementation is needed before adding accelerator-specific kernels.

## Decision

Production numerical arithmetic is Rust-first. CPU is the numerical reference with bounded low-context-switch parallelism. GPU paths are introduced only when profiling proves material benefit and must pass true-transform recovery plus CPU/GPU parity within predefined tolerances. Mixed precision cannot weaken final acceptance statistics.

## Consequences

Python/other languages may orchestrate or interoperate but cannot become an unreviewed second production estimator. GPU release evidence includes backend/runtime version, transfer overhead, peak memory, precision policy, and fallback behavior.