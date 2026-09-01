# Contributing to EmbedRelay

EmbedRelay is a leaf product. **Independent deployment and callability are architecture requirements for every executable release.** The current branch is documentation-first and does not itself claim a runnable release. Do not add a sibling-repo checkout, submodule farm, or monorepo merge as a prerequisite for building, testing, deploying, or calling an executable EmbedRelay release.

## Scope

- Product behavior, contracts, and operator docs belong in this repository.
- Ranking and retrieval fusion belong in RankWeave.
- LLM routing and provider keys belong in contextual-orchestrator.
- Document chunking belongs in the ingest or retrieval host, not here.

Allowed composition hubs are naruon and gyeot. Keep those links. Wire hubs through published contracts in the hub's own repository.

## Documentation

Buyer and operator text stays in `README.md`. Architecture decisions stay in `docs/adr/`. Cite only verified sources in `docs/REFERENCES.md`. Do not invent papers, packages, endpoints, or test harnesses that are not in this tree.

## Pull requests

Open pull requests against `main`. Keep product documentation honest about what this branch actually contains. A documentation-only default branch must not claim a published package, executable release, or live HTTP surface.
