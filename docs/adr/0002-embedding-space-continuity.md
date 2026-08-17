# ADR 0002: Embedding-space continuity and cross-model vector migration

Status: Proposed

## Context

Enterprise retrieval systems accumulate large vector corpora. An embedding
model can be deprecated, revised, regionally unavailable, or replaced for
quality or cost. Immediate full re-embedding is sometimes infeasible. Treating
vectors from different encoding contracts as interchangeable is unsafe: equal
dimension does not imply compatible geometry.

Cross-space mapping is a studied problem. Mikolov et al. (2013) showed that a
linear map can send one distributed word space toward another. Xing et al.
(2015) constrained that map to an orthogonal transform on length-normalized
vectors. Schönemann (1966) gave the orthogonal Procrustes least-squares
solution used by later embedding work. Artetxe et al. (2016) and Smith et al.
(2017) showed that an orthogonal map obtained by singular value decomposition
preserves monolingual geometry better than an unconstrained linear map.
Artetxe et al. (2018) and Lample et al. (2018) studied unsupervised alignment;
those methods can fail under distant or non-comparable conditions and are not
automatic production gates. Moschella et al. (2023) showed that relative
(anchor) coordinates can communicate across latent spaces without claiming
that the spaces are identical.

NIST AI RMF 1.0 requires validity, reliability, and measurement before
deployment decisions (National Institute of Standards and Technology, 2023).
ISO/IEC 23053:2022 treats the trained model and its surrounding data and
software as distinct functional components, which supports registering each
embedding space instead of trusting a vendor model string (International
Organization for Standardization & International Electrotechnical Commission,
2022).

## Decision

EmbedRelay treats cross-model work as a **migration bridge**, not as a
universal inverse and not as a permanent replacement for target-native
vectors.

1. Every embedding space has an immutable identity covering model revision,
   input role, preprocessing, normalization, dimension, scalar precision,
   metric contract, and other material encoding parameters. A provider or
   model name is not that identity.
2. Vectors from different space identities are never compared directly.
3. Adapters are directional (A→B is not B→A). Query and document roles are
   distinct by default. Production chains are one hop by default.
4. Orthogonal Procrustes and regularized linear maps are the default
   scientific starting point when paired anchors exist and assumptions hold.
   Unsupervised or relative-representation methods may be evaluated; they do
   not become automatic cutover gates without retrieval-level evidence.
5. A translated vector carries origin `translated`, adapter provenance, and
   measured fidelity. The desired terminal state is target-native backfill
   whenever source data and policy permit it.
6. Low-confidence or out-of-distribution cases abstain. Abstention is a
   normal product outcome.

## Consequences

- Operators can keep retrieval available during model change without pretending
  that mapped vectors are native.
- Space-identity drift (same vendor label, different outputs) registers a new
  or quarantined space instead of mutating the old one.
- Cutover requires retrieval-level evidence, not vector cosine alone.
- Source indexes remain until a rollback window is accepted.
- Claiming exact invertibility between arbitrary embedding models is rejected.

## References

Artetxe, M., Labaka, G., & Agirre, E. (2016). Learning principled bilingual
mappings of word embeddings while preserving monolingual invariance. In
*Proceedings of the 2016 Conference on Empirical Methods in Natural Language
Processing* (pp. 2289–2294). Association for Computational Linguistics.
https://doi.org/10.18653/v1/D16-1250

Artetxe, M., Labaka, G., & Agirre, E. (2018). A robust self-learning method
for fully unsupervised cross-lingual mappings of word embeddings. In
*Proceedings of the 56th Annual Meeting of the Association for Computational
Linguistics (Volume 1: Long Papers)* (pp. 789–798). Association for
Computational Linguistics. https://doi.org/10.18653/v1/P18-1073

International Organization for Standardization & International
Electrotechnical Commission. (2022). *Framework for artificial intelligence
(AI) systems using machine learning (ML)* (ISO/IEC 23053:2022).
https://www.iso.org/standard/74438.html

Lample, G., Conneau, A., Ranzato, M., Denoyer, L., & Jégou, H. (2018). Word
translation without parallel data. In *International Conference on Learning
Representations*. https://openreview.net/forum?id=H196sainb
https://doi.org/10.48550/arXiv.1710.04087

Mikolov, T., Le, Q. V., & Sutskever, I. (2013). *Exploiting similarities
among languages for machine translation* [Preprint]. arXiv.
https://doi.org/10.48550/arXiv.1309.4168

Moschella, L., Maiorca, V., Fumero, M., Norelli, A., Locatello, F., &
Rodolà, E. (2023). Relative representations enable zero-shot latent space
communication. In *The Eleventh International Conference on Learning
Representations*. https://openreview.net/forum?id=SrC-nwieGJ
https://doi.org/10.48550/arXiv.2209.15430

National Institute of Standards and Technology. (2023). *Artificial
intelligence risk management framework (AI RMF 1.0)* (NIST AI 100-1).
U.S. Department of Commerce. https://doi.org/10.6028/NIST.AI.100-1

Schönemann, P. H. (1966). A generalized solution of the orthogonal Procrustes
problem. *Psychometrika, 31*(1), 1–10. https://doi.org/10.1007/BF02289451

Smith, S. L., Turban, D. H. P., Hamblin, S., & Hammerla, N. Y. (2017).
Offline bilingual word vectors, orthogonal transformations and the inverted
softmax. In *International Conference on Learning Representations*.
https://openreview.net/forum?id=r1Aab85gg
https://doi.org/10.48550/arXiv.1702.03859

Xing, C., Wang, D., Liu, C., & Lin, Y. (2015). Normalized word embedding and
orthogonal transform for bilingual word translation. In *Proceedings of the
2015 Conference of the North American Chapter of the Association for
Computational Linguistics: Human Language Technologies* (pp. 1006–1011).
Association for Computational Linguistics.
https://doi.org/10.3115/v1/N15-1104
