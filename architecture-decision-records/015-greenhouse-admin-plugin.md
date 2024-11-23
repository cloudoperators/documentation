# 015-greenhouse-admin-plugin

- Status: [draft] <!-- optional -->
- Deciders: [list everyone involved in the decision] <!-- optional -->
- Date: [YYYY-MM-DD when the decision was last updated] <!-- optional. To customize the ordering without relying on Git creation dates and filenames -->
- Tags: [greenhouse / cloudoperators] <!-- optional -->
- Technical Story: [description | ticket/issue URL] <!-- optional -->

## Context and Problem Statement

PluginDefintions are used within Greenhouse to deploy and configure operational tools. Some of these are intended to be deployed by the Organization into their Namespace in the Greenhouse Central cluster.
The Plugins that are allowed to be deployed into the Central Cluster should be limited to a set of approved Plugins. Furthermore, the configuration of these Plugins should be limited. This is to ensure, that an Organization cannot deploy Plugins that could negatively impact other tenants on the same cluster.

## Decision Drivers <!-- optional -->

- Stability:
  - Ensure that only approved Plugins are deployed into the Central Cluster
  - Ensure that only approved configurations are applied to the Plugins
- Simplicity:
  - It should be familiar for Admins to manage PluginDefinitions
- Enforced Compliance:
  - Ensure that the Organization cannot deploy Plugins that could negatively impact other tenants on the same cluster
- UI Integration:
  - UX for Admin and non-Admin PluginDefintions should be the same

## Considered Options

- PluginDefinition CRD with Admin flag
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

### PluginDefinition CRD with Admin flag

An additional field `deploymentScope` is added to a PluginDefinition. This field is an enum and defaults to `remote`. If set to `central`, the PluginDefinition is allowed to be deployed into the Central Cluster.
This allows with minimal changes to the existing PluginDefinition CRD to control which Plugins are allowed to be deployed into the Central Cluster. A PluginDefinition with the `deploymentScope` set to `all` is allowed to be deployed into remote clusters as well as into the Organization's Namespace in the Central Cluster.

A PluginDefinition with `deploymentScope` set to `central` must have limited configuration options. This is to ensure that the Plugin cannot be configured in a way that could negatively impact other tenants on the same cluster. That also means that only the PluginOptions defined on the PluginDefinition are allowed to be set. Any other configuration options are to be ignored.

| Decision Driver     | Rating | Reason                        |
|---------------------|--------|-------------------------------|
| Stability           | +++    | Good, because PluginDefinitions can be set as Admin    |                                                                                                                                                                                                                                                                | 
| Simplicity | +++    | Good, because for the Endusers the configuration is the same. |
| Enforced Compliance | o     | Neutral, because this depends on the underlying Helm Chart and the allowed PluginOptions. |
| UI Integration | ++      | Good, because the API objects are the same. |

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
