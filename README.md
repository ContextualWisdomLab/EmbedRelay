# EmbedRelay

Embedding continuity infrastructure for safe cross-model vector migration.

The first executable milestone is developed through protected pull requests; the default branch remains intentionally minimal until exact-head CI and review gates pass.

## Repository governance

Executable milestones are developed on ordinary protected branches and integrated through normal protected pull requests. The protected default branch must not host or execute temporary branch-writing materializers, self-deleting finalizers, or one-shot bootstrap authority. Any such authority is retired through a reviewed pull request after its bounded purpose. The organization workflow-lifecycle control plane then disables any residual GitHub Actions registry record or explicitly classifies it as orphaned, with follow-up tracked in `ContextualWisdomLab/.github#945`.
