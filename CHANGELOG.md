# Changelog

All notable changes to EmbedRelay are recorded here. The project has not published its first release; entries remain under **Unreleased** until the complete release-acceptance contract is satisfied.

## Unreleased

### Added

- Fail-closed Rust `float32` embedding-vector validation bound to the complete canonical embedding-space fingerprint. The contract rejects dimension mismatches, non-finite and subnormal components, zero-norm vectors, and scalar-precision mismatches, and permits a metric operation only after both vectors prove identical embedding-space identity rather than merely matching dimensions.
