# ADR-7 Plugin Option overrides

## Decision Contributors

- ...

## Status

- Proposed

## Context and Problem Statement

In Greenhouse Plugins are the primary way to extend the functionality of the Operations Platform. Since there are some Plugins that are required in most clusters, such as `CertManager`, there are PluginPresets. These PluginPresets are a way to define a default configuration for a Plugin, which is deployed to all clusters matching the PluginPreset's selector.

The issue now is that there are some cases where the default configuration between two clusters only differs in one or very few values, e.g. a cluster-specific secret. This is currently not possible with PluginPresets, as they are applied with the same configuration to all clusters matching the selector.

Another issue is setting default values that are valid for all plugins inside of an Organization, or for all plugins for a specific cluster. Currently, this requires setting these values in every Plugin's spec.

Greenhouse should offer a way to override PluginOptionValues for a specific cluster, for all Plugins of a certain PluginDefinition, or for all plugins in an Organization.

## Decision Drivers

- Stability:
  - Overrides should be consistent
  - Overrides should be applied in a deterministic way (most specific last)
  - There should be no conflicts between overrides or constant reconciliation loops
  - Changes to the overrides should be applied to all relevant plugins

- Transparency:
  - End-users should be able to see/understand which overrides are applied to a Plugin

- Compatibility:
  - Overrides should be compatible with existing Plugins
  - Overrides should be compatible with existing PluginPresets

## Decision

A new CRD called `PluginOverride` will be introduced. This CRD specify Overrides that are used to override PluginOptionValues for a specific cluster, for all Plugins of a certain PluginDefinition, or for all plugins in an Organization.

We will introduce a new CRD called `PluginOverride`. This CRD will allow users to override PluginOptionValues.
It will be possible to:

- define a ClusterSelector to specify the relevant clusters
- specify PluginDefinitionNames to only apply values to Plugins instantiated from any listed PluginDefinition
- apply the overrides to all Plugins in an Organization

The Clusters relevant for the override should be determined by the ClusterSelector. The ClusterNames are the names of the clusters that should be affected by the override. The IgnoreClusters are the names of the clusters that should not be affected by the override. The LabelSelector is a metav1.LabelSelector that should be used to select the clusters.

```golang
type ClusterSelector struct{
  LabelSelector * metav1.LabelSelector `json:"labelSelector,omitempty"`
  ClusterNames []string `json:"clusterNames,omitempty"`
  IgnoreClusters []string `json:"ignoreClusters,omitempty"`
}
```

This could look like:

```yaml
kind: PluginOverride
name: my-overrides
spec:
  pluginDefinitionNames:
    - my-plugindefinition # if empty applies to all plugins
  clusterSelector: # if empty applies to all clusters
    - matchLabels:
        my-cluster-label: my-cluster-value
  overrides:
    - path: my-option
      value: value-override
```

The overrides specified by the PluginOverride must be unique. This means that it is not possible to specify two overrides for the same path and different values. The validation should be done by a validating webhook.

There is a central override component, which is able to retrieve the list of relevant overrides for a Plugin. This component will be called from the PluginPresetController during reconciliation of the individual Plugins.
Overrides for Plugins not managed by a PluginPreset will be applied by a separate controller.

The PluginPresetController and the PluginOverrideController should watch for changes to relevant PluginOverrides and update the respective PluginSpec

The following events should trigger the reconciliation:

- Plugin was updated
- PluginPreset was updated
- PluginOverride was updated

The Plugin's status should contain the list of PluginOverrides that were applied. This ensures that the user can easily see how the Plugin was configured.

All PluginOverrides that are relevant to a Plugin should be applied together. That means if one PluginOverride changes, it is necessary to reapply the whole list to ensure consistency.
The order in which the PluginOverrides are applied to the Plugin are from most generic first, to most specific last.

Order of application of PluginOverrides(most generic first, most specific last):

- PluginOptionValues from Plugin/PluginPreset
- PluginOverrides from PluginOverride **without** Cluster or PluginDefinition
- PluginOverrides from PluginOverride with Cluster **or** PluginDefinition
- PluginOvrrides from PluginOverride with Cluster **and** PluginDefinition

In case that two PluginOverrides specify the same value, they are applied in the order that the PluginOverrides were created. This means that the PluginOverride created first will be applied first.

Furthermore, if a Plugin/PluginPreset already specifies a value that is covered by the override, then the value will be overriden. This ensures that a PluginOverride is able change PluginOptionValues defined by a Plugin/PluginPreset. This is allows to change a value for one Plugin of a PluginPreset, while keeping the values for all others.

## Consequences

- Changes to a PluginOptionValue in a Plugin will be overridden by the PluginOverride Operator. This means overriden values can only be changed by updating the PluginOverride.
- Order of PluginOverrides is fixed from the most general to the most specific last. This means a PluginOverride not specifying Cluster or PluginDefinition will be applied first, and a PluginOverride specifying a Cluster and a PluginDefinition will be applied last.
