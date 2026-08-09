# ADR-0006: Keep production transformation arithmetic in Rust

**Status:** Accepted  
**Date:** 2026-08-09

## Context

Adapter fitting, calibration, evaluation, and large vector transformations are numerically sensitive and may become computationally heavy at enterprise scale. Multiple independent production estimators would make numerical drift, precision behavior, recovery, coverage, and incident diagnosis harder to govern.

## Decision drivers

- one reviewable production arithmetic authority;
- deterministic numerical contracts and true-transform recovery;
- low-context-switch CPU parallelism before accelerator complexity;
- parity-verifiable GPU acceleration only where profiling proves value;
- explicit precision, memory, transfer, and fallback evidence;
- portable orchestration without duplicating the estimator.

## Alternatives considered

1. **Python/NumPy as the production estimator.** Rejected as the governing arithmetic path because it creates another runtime/performance surface and weakens the single numerical authority desired for CWL quantitative software.
2. **GPU-first implementation.** Rejected because accelerator-specific behavior needs a stable reference and many M1/control-plane operations are not computationally material.
3. **Independent CPU and GPU algorithms.** Rejected because performance cannot justify unbounded scientific divergence.
4. **Rust CPU reference plus parity-gated GPU kernels.** Selected for correctness, portability, and bounded optimization.

## Decision

Production numerical arithmetic is Rust-first. CPU is the numerical reference, using bounded worker pools and avoiding thread oversubscription. GPU paths are introduced only after profiling shows material benefit and must pass true-transform/parameter recovery plus CPU/GPU parity within predefined tolerances. Mixed precision may accelerate intermediates but may not weaken final acceptance statistics, calibration, or reproducibility evidence.

## Consequences

Python or other languages may orchestrate, validate interfaces, benchmark, or interoperate, but cannot become an unreviewed second production estimator. GPU releases need backend/runtime identity, device profile, transfer overhead, peak VRAM, batch policy, precision policy, and fallback cause. Optimization work must preserve equation-level behavior and release thresholds.

## Failure and recovery

A GPU OOM, unsupported device/runtime, parity failure, non-finite result, or tolerance breach fails that accelerated path. The operation either falls back to the accepted CPU implementation under explicit policy or fails closed; it never silently substitutes approximate output. Recovery fixes the kernel/runtime or narrows the supported profile and reruns recovery/parity benchmarks.

## Security and governance impact

Compute backends process potentially sensitive vectors and anchors. Device/runtime diagnostics must not expose vector contents. Dynamically loaded kernels/artifacts are supply-chain inputs and require immutable version/digest controls where introduced. A benchmark or model agent cannot authorize a numerical release by itself.

## Verification and acceptance evidence

Each algorithm requires deterministic fixtures, true-transform recovery where identifiable, property tests, edge/non-finite/resource tests, exact production statement/branch/function/line coverage where exposed, CPU multithread determinism within declared tolerance, reproducible benchmarks, and — when GPU exists — real no-skip GPU execution plus CPU/GPU parity across realistic shapes and precision modes.

## Migration and rollback

Introducing a new backend does not change stored adapter semantics. Backend/runtime versions are recorded with fit/evaluation evidence. Rollback selects the previous accepted backend or CPU reference without rewriting historical artifacts; any artifact whose learned parameters change is versioned separately.

## Supersession

A later ADR may change implementation language or numerical authority only with equivalent recovery, coverage, interoperability, security, performance, and rollback evidence. Until then Rust CPU remains the reference and accelerator paths remain subordinate to parity evidence.