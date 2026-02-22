# DeepWiki Coverage Map

This map records how all 29 DeepWiki pages were synthesized into the canonical FocusCue documentation set in this repository.

## Synthesis decisions

1. **Condensed topology**: used a canonical docs set instead of a 29-file mirror to reduce duplication and maintenance overhead.
2. **Code-verified content**: claims were aligned with current repository behavior in `FocusCue/*.swift`, project config, and workflows.
3. **FocusCue-only phrasing**: content was re-authored for FocusCue terminology and runtime behavior.
4. **Section-level traceability**: each DeepWiki page maps to one or more concrete destination sections.

## Mapping table (all 29 pages)

| DeepWiki ID | DeepWiki page | Canonical destination(s) |
| --- | --- | --- |
| `1` | Overview | [`../README.md#focuscue`](../README.md#focuscue), [`PRD.md#product-definition`](PRD.md#product-definition), [`architecture.md#architecture-overview`](architecture.md#architecture-overview) |
| `2` | Getting Started | [`../README.md#quick-start`](../README.md#quick-start), [`user-workflows.md#workflow-1-first-launch-and-onboarding`](user-workflows.md#workflow-1-first-launch-and-onboarding) |
| `2.1` | Building & Running | [`development-and-release.md#local-build-flows`](development-and-release.md#local-build-flows), [`../README.md#quick-start`](../README.md#quick-start) |
| `2.2` | First Launch & Onboarding | [`user-workflows.md#workflow-1-first-launch-and-onboarding`](user-workflows.md#workflow-1-first-launch-and-onboarding), [`integrations-and-operations.md#permissions-and-entitlements-runtime-behavior`](integrations-and-operations.md#permissions-and-entitlements-runtime-behavior) |
| `3` | Architecture | [`architecture.md#architecture-overview`](architecture.md#architecture-overview), [`architecture.md#layered-architecture-and-subsystem-boundaries`](architecture.md#layered-architecture-and-subsystem-boundaries) |
| `3.1` | System Overview | [`architecture.md#layered-architecture-and-subsystem-boundaries`](architecture.md#layered-architecture-and-subsystem-boundaries), [`architecture.md#dependency-graph`](architecture.md#dependency-graph) |
| `3.2` | Application Lifecycle | [`architecture.md#app-lifecycle-launch-url-handling-windowmenu-behavior`](architecture.md#app-lifecycle-launch-url-handling-windowmenu-behavior) |
| `3.3` | Service Layer | [`architecture.md#service-layer-orchestration-focuscueservice-as-center`](architecture.md#service-layer-orchestration-focuscueservice-as-center), [`technical-reference.md#focuscueservice`](technical-reference.md#focuscueservice) |
| `4` | User Interface | [`user-workflows.md`](user-workflows.md), [`technical-reference.md#module-level-reference-keyed-to-source-files`](technical-reference.md#module-level-reference-keyed-to-source-files) |
| `4.1` | Main Window | [`user-workflows.md#workflow-2-script-creation-editing-and-page-organization`](user-workflows.md#workflow-2-script-creation-editing-and-page-organization), [`user-workflows.md#workflow-3-start-and-stop-playback`](user-workflows.md#workflow-3-start-and-stop-playback) |
| `4.2` | Component Library | [`technical-reference.md#module-level-reference-keyed-to-source-files`](technical-reference.md#module-level-reference-keyed-to-source-files) |
| `4.3` | Theme & Design System | [`../docs/design-tokens.md`](../docs/design-tokens.md), [`technical-reference.md#settings-surface-and-effect-matrix`](technical-reference.md#settings-surface-and-effect-matrix) |
| `5` | Core Features | [`PRD.md#functional-requirements`](PRD.md#functional-requirements), [`user-workflows.md`](user-workflows.md) |
| `5.1` | Script Management | [`user-workflows.md#workflow-2-script-creation-editing-and-page-organization`](user-workflows.md#workflow-2-script-creation-editing-and-page-organization), [`data-and-storage.md#core-data-model`](data-and-storage.md#core-data-model) |
| `5.2` | Playback Engine | [`architecture.md#core-runtime-data-flow`](architecture.md#core-runtime-data-flow), [`user-workflows.md#workflow-3-start-and-stop-playback`](user-workflows.md#workflow-3-start-and-stop-playback) |
| `5.3` | Overlay System | [`technical-reference.md#notchoverlaycontroller`](technical-reference.md#notchoverlaycontroller), [`user-workflows.md#workflow-4-overlay-mode-selection-and-behavior`](user-workflows.md#workflow-4-overlay-mode-selection-and-behavior) |
| `5.4` | Speech Recognition & Voice Tracking | [`integrations-and-operations.md#speech-backends-apple-vs-deepgram`](integrations-and-operations.md#speech-backends-apple-vs-deepgram), [`technical-reference.md#speechrecognizer`](technical-reference.md#speechrecognizer) |
| `5.5` | Remote & External Displays | [`user-workflows.md#workflow-5-external-display-and-remote-browser-output`](user-workflows.md#workflow-5-external-display-and-remote-browser-output), [`integrations-and-operations.md#browser-remote-operational-behavior`](integrations-and-operations.md#browser-remote-operational-behavior) |
| `6` | Data & Persistence | [`data-and-storage.md#persistence-architecture`](data-and-storage.md#persistence-architecture), [`data-and-storage.md#dirty-state-and-digest-logic`](data-and-storage.md#dirty-state-and-digest-logic) |
| `6.1` | Data Model | [`data-and-storage.md#core-data-model`](data-and-storage.md#core-data-model), [`technical-reference.md#contract-table-document-formats-and-schema-wrappers`](technical-reference.md#contract-table-document-formats-and-schema-wrappers) |
| `6.2` | Storage Architecture | [`data-and-storage.md#persistence-architecture`](data-and-storage.md#persistence-architecture), [`data-and-storage.md#recovery-and-reconciliation-behavior`](data-and-storage.md#recovery-and-reconciliation-behavior) |
| `7` | Development & Deployment | [`development-and-release.md`](development-and-release.md) |
| `7.1` | Build System | [`development-and-release.md#local-build-flows`](development-and-release.md#local-build-flows), [`development-and-release.md#build-system-structure`](development-and-release.md#build-system-structure) |
| `7.2` | CI/CD Pipeline | [`development-and-release.md#ci-workflow-behavior`](development-and-release.md#ci-workflow-behavior) |
| `7.3` | Release Process | [`development-and-release.md#release-workflow-behavior`](development-and-release.md#release-workflow-behavior), [`development-and-release.md#required-secrets`](development-and-release.md#required-secrets) |
| `8` | Additional Topics | [`integrations-and-operations.md`](integrations-and-operations.md) |
| `8.1` | Permissions & Entitlements | [`integrations-and-operations.md#permissions-and-entitlements-runtime-behavior`](integrations-and-operations.md#permissions-and-entitlements-runtime-behavior), [`architecture.md#security-and-entitlements-boundary`](architecture.md#security-and-entitlements-boundary) |
| `8.2` | Update System | [`integrations-and-operations.md#update-checker-behavior`](integrations-and-operations.md#update-checker-behavior) |
| `8.3` | Import & Export | [`user-workflows.md#workflow-6-import-presentation-notes-and-save-focuscue`](user-workflows.md#workflow-6-import-presentation-notes-and-save-focuscue), [`integrations-and-operations.md#importexport-operational-pipelines`](integrations-and-operations.md#importexport-operational-pipelines), [`technical-reference.md#contract-table-document-formats-and-schema-wrappers`](technical-reference.md#contract-table-document-formats-and-schema-wrappers) |

## Coverage confirmation

- Total DeepWiki pages mapped: **29/29**.
- Each DeepWiki page contributes to at least one canonical local document section.
- No DeepWiki page is left unmapped.
