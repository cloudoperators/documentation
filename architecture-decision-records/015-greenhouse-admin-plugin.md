# 015-greenhouse-admin-plugin

- Status: [draft] <!-- optional -->
- Deciders: [list everyone involved in the decision] <!-- optional -->
- Date: [YYYY-MM-DD when the decision was last updated] <!-- optional. To customize the ordering without relying on Git creation dates and filenames -->
- Tags: [greenhouse / cloudoperators] <!-- optional -->
- Technical Story: [description | ticket/issue URL] <!-- optional -->

## Context and Problem Statement

Within Greenhouse Plugins are used to deploy and configure operational tools. Some of these tools need to be run in the namespace of an Organization in the Central Cluster.
The list of Plugins that are allowed to be deployed into the Central Cluster should be limited. Only the administrators of the Greenhouse instance should be allowed to deploy any such Admin Plugins.
The configuration of these Plugins should be limited to ensure that the Organization cannot deploy Plugins that could negatively impact other tenants on the same cluster.

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

### AdminPluginDefinition & AdminPlugin

Complete separation between Plugins that can be deployed into the Central Cluster and those that are deployed to remote clusters.

This allows to further restrict the access to these resources, so that the audience for Plugins/PluginDefinitions and AdminPlugin/AdminPluginDefinition can be disjunct.

The CRD can be largely similar, but the underlying controller much simpler as it must not handle both use-cases (central & remote deployments). This also allows to easily restrict to only setting those OptionValues in the AdminPlugin that are defined by the AdminPluginDefinition.

This could also imply that only AdminPluginDefinitions can define a UI application, but regular PluginDefinitions may not. This will make it more explicit and intentional where the UI application will be running. In case of the Plugin it would be misleading to have the UI run in the Central Cluster and the Helm Release in the remote.

| Decision Driver     | Rating | Reason                        |
|---------------------|--------|-------------------------------|
| Stability           | o    |  Neutral, because the API is generally known and similar to the existing Plugings. But incompatible change to UIApplication and migration required.   |                                                                                                                                                                                                                                                                | 
| Simplicity | ++    | Good, because the required controller will be simpler with shared functionality from the Helm Controller. But it requires migration of existing Plugins deployed in the Org namespace. |
| Enforced Compliance | ++     | Good, because config can be enforced on the AdminPluginDefinition |
| UI Integration | o      | Neutral, because the API objects are largely the same. |

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
