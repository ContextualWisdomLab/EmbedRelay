# ADR 0002: Embedding-space continuity and cross-model vector migration

Status: Proposed

## Context

Enterprise retrieval systems accumulate large vector corpora. An embedding model can be deprecated, revised, regionally unavailable, or replaced for quality or cost. Immediate full re-embedding is sometimes infeasible. Treating vectors from different encoding contracts as interchangeable is unsafe: equal dimension does not imply compatible geometry.

Cross-space mapping is a studied problem. Mikolov et al. (2013) showed that a linear map can send one distributed word space toward another. Xing et al. (2015) constrained that map to an orthogonal transform on length-normalized vectors. Schönemann (1966) gave the orthogonal Procrustes least-squares solution used by later embedding work. Artetxe et al. (2016) and Smith et al. (2017) showed that an orthogonal map obtained by singular value decomposition preserves monolingual geometry better than an unconstrained linear map. Artetxe et al. (2018) and Lample et al. (2018) studied unsupervised alignment; those methods can fail under distant or non-comparable conditions and are not automatic production gates. Moschella et al. (2023) showed that relative (anchor) coordinates can communicate across latent spaces without claiming that the spaces are identical.

NIST AI RMF 1.0 requires validity, reliability, and measurement before deployment decisions (National Institute of Standards and Technology, 2023). ISO/IEC 23053:2022 treats the trained model and its surrounding data and software as distinct functional components, which supports registering each embedding space instead of trusting a vendor model string (International Organization for Standardization & International Electrotechnical Commission, 2022).

## Decision

EmbedRelay treats cross-model work as a **migration bridge**, not as a universal inverse and not as a permanent replacement for target-native vectors.

### Versioned embedding-space identity

Every space is represented by an immutable `EmbeddingSpaceIdentityV1` record. The material fields are:

| Field | Contract |
| --- | --- |
| `schema_version` | Literal `1` |
| `provider` | Provider or runtime identity; non-empty string |
| `model_id` | Provider/runtime model identifier; non-empty string |
| `model_revision` | Immutable revision, digest, or deployment revision; absence is represented explicitly as `null`, never omitted by convention |
| `input_role` | `query`, `document`, or another future value introduced only by a new identity-schema version |
| `instruction_profile_sha256` | SHA-256 of the exact instruction/prefix template bytes, or `null` when no instruction is applied |
| `preprocessing_profile_sha256` | SHA-256 of the canonical preprocessing profile |
| `tokenizer_identity` | Versioned tokenizer identity when tokenizer behavior is material and observable; otherwise explicit `null` |
| `truncation_policy` | Canonical structured truncation policy, including effective token/input bound |
| `normalization` | `none`, `l2`, or a future value introduced by a new identity-schema version |
| `dimension` | Positive integer output dimension |
| `scalar_type` | Exact stored/transport scalar representation such as `float32`; new representations require a schema revision if not already enumerated |
| `metric` | Exact comparison contract such as `cosine`, `dot_product`, or `euclidean` |
| `projection_profile_sha256` | Digest of any deterministic projection/quantization/post-processing profile, otherwise explicit `null` |

The identity record is serialized with the JSON Canonicalization Scheme (RFC 8785), encoded as UTF-8, hashed with SHA-256, and named:

`urn:cwl:embed-space:v1:sha256:<lowercase-hex-digest>`

Defaults are never implicit: a material field has either an explicit value or explicit `null` where the schema permits it. Any material-field change produces a new identifier. An existing identifier and its canonical record are immutable and must never be rebound to changed encoding behavior. A provider or model name by itself is not an embedding-space identity.

Vectors with different space identifiers are never compared directly. Adapters are directional (`A -> B` is not `B -> A`), query and document roles are distinct by default, and production chains are one hop unless a separately validated policy explicitly permits otherwise.

### Adapter methods

Orthogonal Procrustes and regularized linear maps are the default scientific starting points when paired anchors exist and their assumptions hold. Unsupervised or relative-representation methods may be evaluated; they do not become automatic cutover gates without retrieval-level evidence. Numerical fitting, linear algebra, confidence estimation, and other mathematical core operations in an executable EmbedRelay release belong in Rust rather than a Python arithmetic layer.

A translated vector carries origin `translated`, source and target space identities, immutable adapter identity/provenance, and measured fidelity. The desired terminal state is target-native backfill whenever source data and policy permit it.

### Versioned migration decision policy

Every trained adapter is evaluated under an immutable `EmbeddingMigrationPolicyV1` artifact before it can be approved. The artifact contains the exact source/target space IDs; anchor-population receipt; split algorithm and seed/material; fitting method and revision; evaluation metrics and metric parameters; confidence level; OOD calibration method and significance level; acceptance limits; rollback limits; and the evidence/provenance from which every numeric limit was derived.

The policy is normative:

1. **No leakage.** Fit, calibration, and final evaluation anchors are disjoint. Assignment is deterministic from stable anchor identity plus the policy identity, or is recorded in an immutable split receipt. The final evaluation partition is never used to fit adapter parameters or tune acceptance limits.
2. **No arbitrary thresholds.** Acceptance, OOD, abstention, and rollback limits must be derived from a documented buyer/SLO requirement, an externally justified scientific criterion, or a pre-registered statistical design. A missing derivation is `hold`, not an invitation to choose a rule of thumb.
3. **Native target baseline.** Retrieval evaluation compares translated retrieval against target-native retrieval on the same held-out requests/corpus. Vector similarity alone cannot approve migration.
4. **Uncertainty-aware gate.** For every required retrieval metric, the policy names the estimator and confidence procedure. Approval requires the policy-defined confidence bound to satisfy its pre-registered acceptance limit; a point estimate alone is insufficient.
5. **OOD gate.** OOD/abstention uses a policy-declared calibrated method (for example, a conformal nonconformity procedure when its assumptions and calibration data are appropriate). Inputs outside the calibrated acceptance region abstain; they are not silently translated.
6. **Failure denominator.** Evaluation reports the full attempted denominator, successful translations, abstentions, invalid inputs, and failed translations. Excluding failures from the denominator is not permitted.
7. **Rollback evidence.** Source-native retrieval remains available until the policy's rollback window closes. Post-cutover monitoring uses the same named evidence variables; crossing a pre-registered rollback boundary reverts traffic to an approved source/dual/native path rather than inventing a new threshold in production.
8. **Immutable decision.** The decision receipt binds policy ID, adapter ID, source/target IDs, data/split receipts, metric results, software revision, and reviewer authority. Changing any of those inputs requires a new decision receipt.

The allowed decision states are `approved`, `hold`, and `rejected`. Missing evidence, an invalid identity, data leakage, an unmet confidence-bound criterion, an OOD-policy failure, or an ungrounded numeric threshold yields `hold` or `rejected`; it cannot be promoted by an LLM judgement.

## Consequences

- Operators can keep retrieval available during model change without pretending that mapped vectors are native.
- Space-identity drift registers a new or quarantined space instead of mutating the old one.
- Cutover requires held-out retrieval-level evidence and a versioned policy, not vector cosine alone.
- Source indexes remain until a rollback window is accepted.
- Low-confidence or out-of-distribution cases abstain as a normal product outcome.
- Claiming exact invertibility between arbitrary embedding models is rejected.
- The first executable contract must make the identity record, policy identifier, decision state, and evidence bindings machine-readable; this ADR is design authority until that contract exists.

## References

Artetxe, M., Labaka, G., & Agirre, E. (2016). Learning principled bilingual mappings of word embeddings while preserving monolingual invariance. In *Proceedings of the 2016 Conference on Empirical Methods in Natural Language Processing* (pp. 2289–2294). Association for Computational Linguistics. https://doi.org/10.18653/v1/D16-1250

Artetxe, M., Labaka, G., & Agirre, E. (2018). A robust self-learning method for fully unsupervised cross-lingual mappings of word embeddings. In *Proceedings of the 56th Annual Meeting of the Association for Computational Linguistics (Volume 1: Long Papers)* (pp. 789–798). Association for Computational Linguistics. https://doi.org/10.18653/v1/P18-1073

International Organization for Standardization & International Electrotechnical Commission. (2022). *Framework for artificial intelligence (AI) systems using machine learning (ML)* (ISO/IEC 23053:2022). https://www.iso.org/standard/74438.html

Lample, G., Conneau, A., Ranzato, M., Denoyer, L., & Jégou, H. (2018). Word translation without parallel data. In *International Conference on Learning Representations*. https://openreview.net/forum?id=H196sainb https://doi.org/10.48550/arXiv.1710.04087

Mikolov, T., Le, Q. V., & Sutskever, I. (2013). *Exploiting similarities among languages for machine translation* [Preprint]. arXiv. https://doi.org/10.48550/arXiv.1309.4168

Moschella, L., Maiorca, V., Fumero, M., Norelli, A., Locatello, F., & Rodolà, E. (2023). Relative representations enable zero-shot latent space communication. In *The Eleventh International Conference on Learning Representations*. https://openreview.net/forum?id=SrC-nwieGJ https://doi.org/10.48550/arXiv.2209.15430

National Institute of Standards and Technology. (2023). *Artificial intelligence risk management framework (AI RMF 1.0)* (NIST AI 100-1). U.S. Department of Commerce. https://doi.org/10.6028/NIST.AI.100-1

Rundgren, A., Jordan, B., & Erdtman, S. (2020). *JSON canonicalization scheme (JCS)* (RFC 8785). Internet Engineering Task Force. https://doi.org/10.17487/RFC8785

Schönemann, P. H. (1966). A generalized solution of the orthogonal Procrustes problem. *Psychometrika, 31*(1), 1–10. https://doi.org/10.1007/BF02289451

Smith, S. L., Turban, D. H. P., Hamblin, S., & Hammerla, N. Y. (2017). Offline bilingual word vectors, orthogonal transformations and the inverted softmax. In *International Conference on Learning Representations*. https://openreview.net/forum?id=r1Aab85gg https://doi.org/10.48550/arXiv.1702.03859

Xing, C., Wang, D., Liu, C., & Lin, Y. (2015). Normalized word embedding and orthogonal transform for bilingual word translation. In *Proceedings of the 2015 Conference of the North American Chapter of the Association for Computational Linguistics: Human Language Technologies* (pp. 1006–1011). Association for Computational Linguistics. https://doi.org/10.3115/v1/N15-1104
