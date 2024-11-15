# 013-greenhouse-plugin-lifecycle

- Status: [draft] <!-- optional -->
- Deciders: [Arno, Ivo, Uwe, David] <!-- optional -->
- Date: [YYYY-MM-DD when the decision was last updated] <!-- optional. To customize the ordering without relying on Git creation dates and filenames -->
- Tags: [greenhouse / cloudoperators] <!-- optional -->
- Technical Story: [description | ticket/issue URL] <!-- optional -->

## Context and Problem Statement

Currently, updates to a plugin are instantly propagated through the entire landscape of a customer.
While E2E and plugin-specific tests increase transparency and worst case trigger rollbacks, a user-configurable, staged deployment is required for risk mitigation.
Discuss a pragmatic approach and define a POC.

**Discussion:**

- Plugin on the greenhouse-extensions.git main branch must be production ready
- Get inspiration from Gardener to inform customer "Upcoming changes in plugin ..." with a grace period. Force upgrade afterwards.
- Classify cluster
- Stable API with migration paths
- Follow engineering policy: Bronze, Silver, Gold with grace period in between.
- Configurable terms for stages; configurable time between stages with greenhouse-enforced maximum.
- Emergency fixes should be possible
- How to handle failed upgrades: rollback vs forward fix (tendency: forward fix)

**Goal:**

- Introduce a concept of tiers for clusters, to stage rollouts of Plugins
- Introduce a Plugin Lifecycle Policy

## Decision Drivers <!-- optional -->

- [driver 1, e.g., a force, facing concern, …]
- [driver 2, e.g., a force, facing concern, …]
- … <!-- numbers of drivers can vary -->

## Considered Options

### Argo Rollouts (Not viable ❌)

Description: A Kubernetes controller and set of CRDs for advanced deployment capabilities including canary deployments, blue-green deployments, and progressive delivery features.

| Decision Driver           | Rating | Reason                                                                                           |
|--------------------------|--------|--------------------------------------------------------------------------------------------------|
| Multi-cluster Management | ---    | Cannot manage rollouts from central cluster; requires controller in every remote cluster          |
| Operational Complexity   | --     | High complexity due to required installation in each cluster                                      |
| Integration Capabilities | +      | Good integration with Kubernetes workloads but requires significant architecture changes          |
| Flexibility             | +++    | Excellent support for various deployment strategies                                               |
| Monitoring              | +++    | Strong metrics-based analysis and verification                                                    |

Key Limitation: Argo Rollouts cannot be used in a centralized manner. [As per their documentation](https://argoproj.github.io/argo-rollouts/FAQ/#can-we-install-argo-rollouts-centrally-in-a-cluster-and-manage-rollout-resources-in-external-clusters), the Rollout controller and CRDs must be installed in every target cluster where progressive delivery is needed. This architectural limitation makes it unsuitable for our centralized plugin management approach, as it would:

1. Significantly increase operational overhead by requiring installation and management in every target cluster
2. Complicate our existing centralized plugin management architecture using the plugin controller
3. Add unnecessary complexity to the current plugin controller's responsibilities
Due to these limitations, especially the inability to manage rollouts from a central cluster, this option is not viable for our use case.

- [option 2]
- [option 3]
- … <!-- numbers of options can vary -->

## Decision Outcome

Chosen option: "[option 1]",
because [justification. e.g., only option, which meets k.o. criterion decision driver | which resolves force force | … | comes out best (see below)].

### Positive Consequences <!-- optional -->

- [e.g., improvement of quality attribute satisfaction, follow-up decisions required, …]
- …

### Negative Consequences <!-- optional -->

- [e.g., compromising quality attribute, follow-up decisions required, …]
- …

## Pros and Cons of the Options | Evaluation of options <!-- optional -->

### [option 1]

[example | description | pointer to more information | …] <!-- optional -->

| Decision Driver     | Rating | Reason                        |
|---------------------|--------|-------------------------------|
| [decision driver a] | +++    | Good, because [argument a]    |                                                                                                                                                                                                                                                                | 
| [decision driver b] | ---    | Good, because [argument b]    |
| [decision driver c] | --     | Bad, because [argument c]     |
| [decision driver d] | o      | Neutral, because [argument d] |

### [option 2]

[example | description | pointer to more information | …] <!-- optional -->

| Decision Driver     | Rating | Reason                        |
|---------------------|--------|-------------------------------|
| [decision driver a] | +++    | Good, because [argument a]    |                                                                                                                                                                                                                                                                | 
| [decision driver b] | ---    | Good, because [argument b]    |
| [decision driver c] | --     | Bad, because [argument c]     |
| [decision driver d] | o      | Neutral, because [argument d] |

### [option 3]

[example | description | pointer to more information | …] <!-- optional -->

| Decision Driver     | Rating | Reason                        |
|---------------------|--------|-------------------------------|
| [decision driver a] | +++    | Good, because [argument a]    |                                                                                                                                                                                                                                                                | 
| [decision driver b] | ---    | Good, because [argument b]    |
| [decision driver c] | --     | Bad, because [argument c]     |
| [decision driver d] | o      | Neutral, because [argument d] |

## Related Decision Records <!-- optional -->

[previous decision record, e.g., an ADR, which is solved by this one | next decision record, e.g., an ADR, which solves this one | … | pointer to more information]

## Links <!-- optional -->

- [Link type](link to adr) <!-- example: Refined by [xxx](yyyymmdd-xxx.md) -->
- … <!-- numbers of links can vary -->
