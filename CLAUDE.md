# EmbedRelay development context

Follow `AGENTS.md` and the organization engineering policy before changing source or contracts.

EmbedRelay owns embedding-space identity, compatibility validation, governed directional migration, abstention, rollback and target-native backfill evidence. Keep adjacent authorities separate: RankWeave for retrieval fusion/evaluation, contextual-orchestrator for production model/provider routing, keyverse for identity-provider integration, embedding runtimes for model execution, vector stores for durable vector persistence, and ingest/retrieval hosts for source interpretation and semantic-unit chunking.

The current repository maturity is pre-release. Do not turn documentation decisions into as-built claims. Production numerical/vector computation belongs in Rust. Any future persistence must use descriptive multiword `snake_case`, explicit tenant isolation, 3NF relational facts, and tested item-level idempotency/UPSERT behavior. Any executable HTTP surface requires OpenAPI and exact-head security/test/release evidence.
