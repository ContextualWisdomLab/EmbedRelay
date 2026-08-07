# Embedding-vector safety contract

## Status

This record doctors the bounded M1 vector-validation slice in `embedrelay-space-contract`. It is not release evidence and does not claim that the broader M1 registry, PostgreSQL persistence, migration, or metric-computation work is complete.

As of 8 August 2026, IEEE 754-2019 remains an active IEEE standard, while IEEE P754 is an active revision project intended to supersede it. ISO/IEC 60559:2020 remains the published international adoption of the IEEE 754-2019 floating-point arithmetic model. Rust 1.97.1 documents `f32` as the single-precision floating-point primitive and exposes the `is_finite` and `is_subnormal` predicates used by this boundary.

## Buyer-visible risk

Two embedding vectors can have equal dimensions while representing incompatible model revisions, input roles, preprocessing policies, normalization strategies, or distance-metric contracts. Treating dimensional equality as compatibility can silently contaminate retrieval during migration. Numeric payloads can also contain NaN, infinity, subnormal values, the wrong number of components, or a degenerate all-zero direction.

The product therefore needs a fail-closed boundary before an embedding may participate in migration or metric work.

## Implemented invariant

`ValidatedEmbeddingVector::new` accepts only a `Vec<f32>` whose manifest declares `numeric_precision_code = "float32"` and whose length exactly matches `vector_dimension`.

Every component must be finite and non-subnormal. The constructor widens each accepted component to `f64` for squared-L2-norm accumulation, rejects a zero norm, and then captures the manifest's complete canonical embedding-space fingerprint plus its distance-metric code.

`same_space_metric_code` returns a metric code only when two validated vectors have identical canonical space fingerprints. Equal dimensions, equal scalar precision, or equal metric labels alone are deliberately insufficient.

## Arithmetic and acceleration boundary

This slice performs validation and one linear norm accumulation only. It does **not** implement cosine distance, dot products, nearest-neighbor search, matrix multiplication, batch scoring, or another computationally material metric kernel.

Accordingly, introducing CPU thread pools or a GPU backend here would add coordination overhead without a material compute workload. Any later computationally material batch metric implementation must remain Rust-first, establish a low-context-switch CPU-parallel reference path, add a GPU backend where materially beneficial, and prove numerical and decision parity against the CPU reference before production use.

## Failure behavior

The boundary rejects, rather than repairs or silently normalizes:

- a manifest precision other than `float32` for this constructor;
- too few or too many components;
- NaN and positive or negative infinity;
- IEEE-754 subnormal components;
- a vector whose squared L2 norm is zero; and
- metric compatibility between different canonical embedding spaces.

The implementation does not mutate the supplied vector values, infer a missing dimension, replace invalid components, or treat a same-dimension vector as same-space evidence.

## TDD evidence

The fail-first commit `ee43cddfb40d2e3f7327cffc6792ce669b3b560b` introduced `vector_contract.rs` before the production vector module existed. CI run `31228192636`, job `93026575747`, failed with Rust `E0432` because `ValidatedEmbeddingVector`, `VectorValidationError`, and `VectorCompatibilityError` were intentionally absent.

The subsequent production implementation and public export made the complete workspace test job pass on head `79c652290096beaeaca2f2b3ab7cbd5d453a5605` before this documentation commit. Final merge evidence must still be taken only from the ultimate exact current head; predecessor-head success is historical TDD evidence, not a merge gate.

## Regression contract

`crates/embedrelay-space-contract/tests/vector_contract.rs` covers:

- exact binding of values, metric code, fingerprint, and norm;
- dimension mismatch;
- NaN, positive infinity, and negative infinity;
- a concrete `f32` subnormal bit pattern;
- positive and negative zero producing zero norm;
- scalar-precision mismatch;
- same-space compatibility; and
- rejection of equal-dimension vectors whose model revision changes the canonical space fingerprint.

The durable CI gate now checks out `github.event.pull_request.head.sha` explicitly, asserts `git rev-parse HEAD` equals that exact PR head, runs the stable workspace tests, and uses pinned `cargo-llvm-cov` 0.8.6 with pinned `nightly-2026-08-01` branch instrumentation. It fails closed unless LLVM reports every line, region, function, and branch covered. Rust/LLVM does not expose an independent statement-count metric; region coverage is retained alongside line and branch coverage rather than relabelled as statement coverage.

On predecessor exact head `8c53a7d651f204570a84127b9ebd6091a915c6ff`, CI run `31228584594`, job `93027659997`, explicitly checked out and asserted that SHA, passed all 20 workspace regression tests, and reported 197/197 lines, 261/261 regions, 30/30 functions, and 22/22 branches covered. Those values establish that the gate works on an exact PR head, but they remain historical evidence after any later commit. Promotion, merge, or release requires the same gate to succeed on the ultimate exact current head.

## Monitoring

Operational telemetry added by later persistence or migration layers should count validation failures by stable reason code without logging vector payloads, raw model inputs, credentials, or tenant-sensitive material. A rising failure rate should be investigated as a producer-contract or migration-boundary regression rather than automatically bypassed.

## Rollback

This contract is additive and has no persisted-data migration in this slice. Before release, rollback consists of reverting the vector module, its public exports, tests, doctoring record, and changelog entry together. Once downstream persisted data is admitted through this validator, rollback must preserve the recorded embedding-space fingerprint and must never reinterpret previously rejected vectors as compatible without an explicit, separately reviewed migration policy.

## References

Institute of Electrical and Electronics Engineers. (2019). *IEEE standard for floating-point arithmetic (IEEE Std 754-2019).* https://doi.org/10.1109/IEEESTD.2019.8766229

International Organization for Standardization, & International Electrotechnical Commission. (2020). *Information technology—Microprocessor systems—Floating-point arithmetic (ISO/IEC 60559:2020).* https://www.iso.org/standard/80985.html

The Rust Project Developers. (2026). *Primitive type `f32` (Rust 1.97.1 standard library documentation).* https://doc.rust-lang.org/stable/std/primitive.f32.html

Institute of Electrical and Electronics Engineers. (2024). *P754: Standard for floating-point arithmetic* [Active project authorization request]. https://standards.ieee.org/ieee/754/11684/
