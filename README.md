# EmbedRelay

Embedding continuity infrastructure for safe cross-model vector migration.

The first executable milestone is developed through protected pull requests; the default branch remains intentionally minimal until exact-head CI and review gates pass.

## Repository governance

Executable source is developed on ordinary branches and integrated through normal protected pull requests. The protected default branch must not retain temporary branch-writing materializers, self-deleting finalizers, or one-shot bootstrap authority after their bounded purpose. Retirement of such authority is itself performed through a reviewed pull request, and any residual GitHub Actions registry record is reconciled separately through the organization workflow-lifecycle control plane.
