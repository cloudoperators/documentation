# 013-greenhouse-plugin-lifecycle

- Status: [draft] <!-- optional -->
- Deciders: [Arno, Ivo, Uwe, David] <!-- optional -->
- Date: [YYYY-MM-DD when the decision was last updated] <!-- optional. To customize the ordering without relying on Git creation dates and filenames -->
- Tags: [greenhouse / cloudoperators] <!-- optional -->
- Technical Story: [description | ticket/issue URL] <!-- optional -->

## Context and Problem Statement

Greenhouse uses Plugins to provide cluster administrators with the ability to deploy and manage operations tooling on their Kubernetes clusters.
PluginDefinitions define the Helm Chart and it's default settings. A Plugin is a particular configuration of a PluginDefinition, which can set additional settings and targets a specific cluster.

The PluginDefinition is a cluster-scoped resource. That means, a PluginDefinition is available for all Organizations in the same Greenhouse instance. An update to a PluginDefinition will affect all Organizations and using this PluginDefinition.
The current mechanism updates all Plugins in all Organizations instantly. This is a risk, as a faulty PluginDefinition update can break all clusters using this PluginDefinition.
Also there is no option to pin the used PluginDefinition version for a Plugin.

In order to mitigate this risk, there are E2E and plugin-specific tests in place. However, these tests are not sufficient to prevent all possible issues.

The goal of this ADR is to define a concept that allows:

- to stage the rollout of new PluginDefinition versions
- to allow pinning of PluginDefinition versions for Plugins
- to allow multiple versions of a PluginDefinition to be availalbe in a Cluster
- to provide more insights into the PluginDefinition changes to the customer
  - Changelog for the PluginDefinition?
  - Migration tasks for the PluginDefinition?
  - Helm Diff for the Plugin?

**Discussion:**

- Plugin on the greenhouse-extensions.git main branch must be production ready
- Get inspiration from Gardener to inform customer "Upcoming changes in plugin ..." with a grace period and let him update for testing. Force upgrade afterwards.
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

- Multiple versions of a PluginDefinition
- Pinning of PluginDefinition versions for Plugins
- Rollback on Failure
- Staged Rollouts
- Reporting of Plugin changes to the customer

## Considered Options

- Argo Rollouts (Not viable ❌)
- PluginPreset as the Orchestrator for Plugins
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

### PluginPreset as the Orchestrator for Plugins

Description: The existing PluginPreset CRD already manages part of the Lifecycle for Plugins. Currently it allows to configure Plugins for multiple clusters. If the PluginPreset is extended to manage the PluginDefinition versions, then it can be used to orchestrate the Plugin Lifecycle.

In this approach, the PluginPreset would be extended to allow the following:

- Plugin is extended to include the PluginDefinition version to be used
- Value defaulting is done by the PluginPreset
- If a PluginDefinition requires additional required values, the PluginPreset will stop the Plugin from being updated
- PluginPreset will need an aggregated status of all managed Plugins
- UI only shows PluginPreset, not Plugin

The PluginPreset already allow to target a set of clusters by labelSelector. The used label can be used to classify the clusters into different tiers.

By adding additional validation on the PluginPreset level, the PluginPreset can be used to stop upgrades of Plugins, if the PluginDefinition requires additional values.

By allowing the user to only edit the PluginPreset, there is no need to ensure the user makes invalid changes to the Plugin.

It is very important that the PluginDefinitions and the used Helm Charts are sufficiently tested before they are merged and released. There also needs to be extra validation in the PR to ensure that the PluginDefinition is not changed in a way that breaks between minor versions. Additional required values must only be added or removed in a major version. This is to ensure that the PluginPreset can be used to stop the Plugin from being updated, before the OptionValues are fixed.

```mermaid
flowchart LR

subgraph PluginCatalog.git
  pd-old-git[PluginDefinition v0.5.1]
  pd-new-git[PluginDefinition v1.0.0]
end


subgraph Greenhouse
  subgraph Greenhouse Namespace
   pp-controller[PluginPreset Controller]
   hc-controller[Helm Controller]
   pc-controller[PluginCatalog Controller]
  end
  subgraph Organization
    pc[PluginCatalog]
    pd-old["PluginDefinition [version=0.5.1]"]
    pd-new["PluginDefinition [version=1.0.0]"]
    pp-qa["PluginPreset [environment=qa]"]
    pp-prod["PluginPreset [environment=prod]"]

    gc-qa@{ shape: procs, label: "Clusters [environment=qa]"}
    gc-prod@{ shape: procs, label: "Clusters [environment=prod]"}

    gp-qa@{ shape: procs, label: "Plugins [environment=qa]"}
    gp-prod@{ shape: procs, label: "Plugins [environment=prod]"}
  end
end

c-qa@{ shape: procs, label: "QA Clusters"}
c-prod@{ shape: procs, label: "Production Clusters"}

pc-controller --fetches--> pd-old-git
pc-controller --fetches--> pd-new-git
pc-controller --reconciles--> pc
pc-controller --creates--> pd-old
pc-controller --creates--> pd-new

pp-controller --reconciles--> pp-qa
pp-controller --reconciles--> pp-prod
hc-controller --reconciles--> gp-qa
hc-controller --reconciles--> gp-prod

pp-qa-.selects.->gc-qa
pp-qa-.pins.->pd-old
pp-controller--creates-->gp-qa
hc-controller --deploys--> c-qa

pp-prod-.selects.->gc-prod
pp-prod-.pins.->pd-new
pp-controller--creates-->gp-prod
hc-controller --deploys--> c-prod

```

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
