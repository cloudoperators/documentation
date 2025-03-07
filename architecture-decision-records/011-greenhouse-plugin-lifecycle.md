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
- to allow multiple versions of a PluginDefinition to be available in a Cluster
- to provide more insights into the PluginDefinition changes to the customer
  - Changelog for the PluginDefinition?
  - Migration tasks for the PluginDefinition?
  - Helm Diff for the Plugin?
- Introduce a concept of tiers for clusters, to stage rollouts of Plugins
- Introduce a Plugin Lifecycle Policy
- There must be a way to handle breaking changes due to Plugin updates

**Discussion:**

- Plugin on the greenhouse-extensions.git main branch must be production ready
- Get inspiration from Gardener to inform customer "Upcoming changes in plugin ..." with a grace period and let him update for testing. Force upgrade afterwards.
- Classify cluster
- Stable API with migration paths
- Follow engineering policy: Bronze, Silver, Gold with grace period in between.
- Configurable terms for stages; configurable time between stages with greenhouse-enforced maximum.
- Emergency fixes should be possible
- How to handle failed upgrades: rollback vs forward fix (tendency: forward fix)

## Decision Drivers <!-- optional -->

- Multiple versions of a PluginDefinition
- Pinning of PluginDefinition versions for Plugins
- Rollback on Failure
- Staged Rollouts
- Reporting of Plugin changes to the customer

## Considered Options

- Argo Rollouts (Not viable ❌)
- PluginPreset as the Orchestrator for Plugins
- FluxCD
- PluginDefinitionRevisions and external GitOps workflow
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
|  Multiple versions of a PluginDefinition | o   | Neutral, because the proposed option requires additional complexity inside the PluginPresetController to allow keeping multiple Version of a PluginDefinition to support a staged rollout. This proposal only considers PluginPresets. Plugins are auto-upgraded on every PluginDefinition update.   |                                                                                                                                                                                                                                                                | 
| Pinning of PluginDefinition versions for Plugins | ++    | Good, because the proposed changes to the PluginPreset will allow to pin a PluginDefinition.    |
| Rollback on Failure | +     | Ok, because the PluginPresetController has full control over the PluginDefinitions.     |
| Staged Rollouts | o      | Neutral, because multiple version upgrades in short succession may or may not interfere with the order of upgrading the PluginPreset. This proposal only considers PluginPresets. Plugins are auto-upgraded on every PluginDefinition update. |
| Reporting of Plugin changes to the customer | o      | Neutral, because [argument d] |

### [PluginPreset as Orchestrator with support for Breaking changes / update opt-in/out]

[example | description | pointer to more information | …] <!-- optional -->

Description: Like PlugionPreset Orchestrator idea above with more features for the sake of customer happiness.

#### Breaking changes
There needs to be a flag or sth to block a plugin rollout automatically from master, if a breaking change is introduced.

In case there are blockers for rolling out automatically there need to be a blocker flag / label which will prohibit the rollout of newer versions to customer clusters.

Customers need to made aware that an update is pending (notification via UI (alert bell?)/Slack) and that they have to actively migrate.

* Introduce a timer counting backwards in the UI
* Introdcue alerts
    * we need to export this as a metric if there are pending updates

#### Update windows

Customers will usually rarely update and the amount of different plugin versions should be rather minimal. However the updates should never be rolled out without the customer being aware of it. 

Idea: introduce update windows which are mandatory to set either globally or on a per plugin base. Could be in a cronjob style manner. The Controller will only attempt to update Plugins during given window.
Maybe only offer to set the time window to a day of week/time to have the possibility of updating at least weekly.


| Decision Driver     | Rating | Reason                        |
|---------------------|--------|-------------------------------|
|  Multiple versions of a PluginDefinition | +++    | Good, because [argument a]    |                                                                                                                                                                                                                                                                | 
| Pinning of PluginDefinition versions for Plugins | ---    | Good, because [argument b]    |
| Rollback on Failure | --     | Bad, because [argument c]     |
| Staged Rollouts | o      | Neutral, because [argument d] |
| Reporting of Plugin changes to the customer | o      | Neutral, because [argument d] |

### Flux

This is a tool that can orchestrate resources from a central plane. It does not require any CRDs in remote planes, it integrates nicely with amongst others Helm and Kustomise. Using the tool [Flagger.app](https://flagger.app), various deployment strategies can be utilised.

|<div style="width:200px"> Decision Driver </div>    | Rating | Reason |
|---------------------|--------|-------------------------------|
| Multi-tenancy (Admin-remote cluster management) | +++ | This tool is natievly supporting [multi-tenancy](https://fluxcd.io/flux/installation/configuration/multitenancy/). |
| HelmRelease trigger  | ++ | FluxCD [can fetch and listen](https://fluxcd.io/flux/components/helm/) for new Helm releases and automatically roll-them out. |
| GitOps support | + | Rolling out with e.g. Github Actions is [possible](https://fluxcd.io/flux/use-cases/gh-actions-helm-promotion/). |
| No CRDs in remote-clusters | ++ | [At a brief glance](https://fluxcd.io/flux/installation/configuration/multitenancy/), FluxCD [seems](https://github.com/fluxcd/flux2-hub-spoke-example) to not require CRDs/resources in remote-clusters for Helm related installs only the admin-cluster requires CRDs e.g. the so-called 'HelmRelease'. However, it is not clear whether Flagger or with e.g. Kustomize requires CRDs in remote-clusters. |
| Deployment strategies (Flagger) | + | [Docs](https://docs.flagger.app/install/flagger-install-with-flux) |
| Scope in restructuring the roll-out | -- | To integrate Flux properly, and possibly Flagger, there will be an overhead in restructuring the logic. |
| Added complexity | -- | This tool would bring additional complexity (in the sense of integration efforts, dependency managment, customisation etc) to our landscape.† |
| Kustomize roll-out of PluginDefintions | ? | Using Kustomize to roll-out PluginDef updates could control version updates on PluginDefs. Could require some refactoring and introduce complexity in the Plugin authoring. |

> † The task of a controlled and high-quality roll-out managment is arguably a complex task, so this might be unavoidable.

**The crucial point** of using Flux however is to create a strategy for rolling out to specific clusters in a controlled way. The multi-tennancy only gets us _that_ far, to promote specific clusters at a given time requires some control. Possibly through manual intervention, see discussions about this [here](https://github.com/fluxcd/flux2/issues/611).

#### As a flowchart

```mermaid
flowchart LR
  subgraph firstApproval
    Author --> Plugin
    Plugin --> PR
    codeOwner["Code Owner"]
    codeOwner --> PR
    Action["GitHub Action, Deploy new Helm Chart"]
    PR --> Action
    HelmChart["New published Helm chart, vX.Y.Z"]
    Action --> HelmChart
    flux --> HelmChart

    subgraph qaClusuter [QA Clusters]
    q1["QA-1"]
    q2["QA-2"]
    q3["QA-3"]
    q4["QA-4"]
    end

    subgraph AdminCluster
    flux --> q1
    flux --> q2
    flux --> q3
    flux --> q4
    end
  end

  subgraph secondApproval
    subgraph bronzeCluster [Bronze Clusters]
    b1["Bronze-1"]
    b2["Bronze-2"]
    b3["Bronze-3"]
    b4["Bronze-4"]
    end

    subgraph silverCluster [Silver Clusters]
    s1["Silver-1"]
    s2["Silver-2"]
    s3["Silver-3"]
    s4["Silver-4"]
    end

    subgraph goldCluster [Gold Clusters]
    G1["Gold-1"]
    G2["Gold-2"]
    G3["Gold-3"]
    G4["Gold-4"]
    end
  end

  flux --> app@{ shape: diamond, label: "Approval Process" }
  productionApprover["Approver for Production"]
  productionApprover --> app

  app --> bronzeCluster
  app --> silverCluster
  app --> goldCluster

```

#### As a sequence diagram

```mermaid
sequenceDiagram
box firstApproval First Approval
  actor Author as Plugin Author
  participant PR as Pull Request with new changes
  actor codeOwner as Code Owner
  participant Action as GitHub Action
  participant HelmChart as Helm Package Registry
  participant flux as Admin cluster running Flux

  participant qa as QA Clusters
end

  Author->>+ PR: Author creats a PR
  codeOwner ->> PR: Approval cycle
  PR ->>- Author: PR is Approved
  Author ->> PR: Merges PR
  PR ->> Action: GitHub Action Deploy new Helm Chart

  Action ->> HelmChart: Deploys a new Helm Chart vX.Y.Z
  flux ->> HelmChart: Polls Helm Package registry for a new version
  
  flux ->> qa: Roll out new helm release to Q1,Q2,QX
  
  box secondApproval
    actor approver as Approver
    participant app as Approval Process
  
    participant bronze as Bronze Clusters
    participant silver as Silver Clusters
    participant gold as Gold Clusters
  end
  

  note right of approver: The approver will press the production<br/>roll-out button to fire it away.
  note right of app: The process should allow<br/>for a controlled process.<br/>For example merge to a<br/>specific branch, a specific<br/>semver or some other identifier‡
  approver ->> app: A person approves the roll out to production
  flux ->> bronze: Roll out new helm release to Bronze 1,2,X...
  flux ->> silver: Roll out new helm release to Silver 1,2,X...  
  flux ->> gold: Roll out new helm release to Gold 1,2,X...
```

> ‡ For instance promoting using [an action and PR](https://fluxcd.io/flux/use-cases/gh-actions-helm-promotion/#define-the-promotion-github-workflow)

| Decision Driver     | Rating | Reason                        |
|---------------------|--------|-------------------------------|
|  Multiple versions of a PluginDefinition | +++    | Good, because [argument a]    |                                                                                                                                                                                                                                                                | 
| Pinning of PluginDefinition versions for Plugins | ---    | Good, because [argument b]    |
| Rollback on Failure | --     | Bad, because [argument c]     |
| Staged Rollouts | o      | Neutral, because [argument d] |
| Reporting of Plugin changes to the customer | o      | Neutral, because [argument d] |

### PluginDefinitionRevisions and external GitOps workflow

The current implementation of PluginDefinitions does not support deploying multiple versions of the same PluginDefinition. This brings limitations to any rollout strategy, as all Plugins refer to the same PluginDefinition. If the PluginDefinition is updated, so will the Plugins referencing it. This means staging rollouts is not possible, and any breaking changes will affect all Plugins.
Furthermore, the PluginDefinition is on the cluster scope, meaning an update affects all Organizations in the same Greenhouse instance at the same time.

This design has the following limitations:

- Changes to the defaults set by a PluginDefinition do not immediately take affect. The defaulting is done during the admission of a Plugin. That means if no changes to the Plugin are done, a potentially required new default value may be missing.
- Using the existing PluginDefintion and it's version for a staged rollout will break, as soon as there is another version introduced during an active rollout. The HelmChart version and PluginOptions of the in progress rollout are overwritten.
- In the case of a bad update, there is no way to rollback to a previous version of the PluginDefinition. The Plugin is stuck in a broken state, depending on the issue and the HelmController a rollback to the previous state may or may not be possible. Either way the Plugin cannot be updated to the previous version of the PluginDefinition. Only a rollback of the whole PluginDefinition is possible, which will affect all Plugins using this PluginDefinition.

To address these issues a new PluginDefinitionRevision CRD is proposed. The PluginDefinitionRevision should similar to a revision of a Helm release provide a snapshot of the PluginDefinition at a certain version. The PluginDefinitionRevision is immutable and stores the `version`, `pluginOptions` and `helmChart` of a PluginDefinition. There may be multiple revisions for a single PluginDefinition.
Instead of referencing a PluginDefinition, a Plugin and PluginPreset should reference a PluginDefinitionRevision. This will allow to stage rollouts of new PluginDefinitions, as well as provide a way to rollback to a previous version of a PluginDefinition. Also updates to a PluginDefinition will not affect an in progress rollout.

The relationship between the different CRDs is depicted in the following ERD:

```mermaid
erDiagram
PluginDefinition ||--|{ PluginDefinitionRevision : has 
PluginPreset }o--|| PluginDefinitionRevision : ref
Plugin }o--|| PluginDefinitionRevision : ref
PluginPreset ||--|{ Plugin : owns

PluginDefinition {
    string    version
    object    helmChart
    object[]  pluginOption
}

PluginDefinitionRevision {
    int       revision
    string    version
    object    helmChart
    object[]  pluginOption
}

Plugin {
    string    pluginDefinition
    string    pluginDefinitionVersion
    string    clusterName
    object[]  pluginOptionValues
}

PluginPreset {
    string    pluginDefinition
    string    pluginDefinitionVersion
    object[]  pluginOptionValues
    object[]  clusterOverrides

}
```

The PluginDefinitionRevision is immutable and is written each time the PluginDefinition is changed. This needs to be enforced during the PluginDefinition admission, so that inconsistent updates can be prevented.
The requirement to change the used PluginDefinition version in the spec of a Plugin, ensures that the Admission and the defaulting are done correctly. (_Note: This mechanism could also be used for deprecating, removing or migration PluginOptionValuse between two versions_)

The PluginPreset already manages some aspects of the Plugin lifecycle. Additionally, it could be extended to support semantic version constraints as part of this change. This would allow for semi-automatic updates if desired. In such a scenario, the PluginPreset could have a semantic version constraint on a certain minor version but allow any patch versions. (e.g. `^v1.1.x`) In this scenario any new PluginDefinitionRevision that brings a higher patch level would automatically be deployed.
This version constraint will not be supported on the Plugin, since the known limitations of defaulting and admission would not be addressed.

```yaml
apiVersion: greenhouse.sap/v1alpha1
kind: PluginPreset
metadata:
  name: cert-manager
spec:
  clusterSelector: {...}
  plugin:
    ...
    optionValues: {}
    pluginDefinition:
      name: cert-manager
      version: "^v1.1.x"
    releaseNamespace: kube-system
```

The current case of automatically upgrading will also be supported by this mechanism. The PluginPreset can be configured to only pin the major version or not pin at all. This will allow for a fully automatic update of the PluginDefinition, if desired.

The proposed changes only provide a way to control the update of a Plugin, but do not provide a way to rollout the changes. There are already many proven solutions and mechanisms that can be used. Therefore, Greenhouse should not provide a lock-in to any particular solution. Rather, it should provide the means to integrate with them.
This option can also support a workflow as described in Option 3, where a 4-eyes principle is proposed for production changes.

The PluginCatalog, discussed in a parallel ADR, should consider the support of a Renovate compatibe source. This way the updates of PluginPresets/Plugins can be supported via Renovate Pull Requests.

It will also be possible to support this mechanism of version pinning from the UI. Here, it should be possible to select the PluginDefinition Version from the list of available PluginDefinitionRevisions.

Now the Platform is still at an early stage where frequent updates of the PluginDefinitions are taking place. However, there needs to be a way to control the maximum number of revisions for a PluginDefinition. This is to prevent an unlimited number of revisions, and on the other hand there still needs to be a way to force the upgrade of a Plugin/PluginDefinition.

[example | description | pointer to more information | …] <!-- optional -->

| Decision Driver     | Rating | Reason                        |
|---------------------|--------|-------------------------------|
| Multiple Versions of a PluginDefinition | +++    | Good, because PluginDefinitionRevisions provide a way to switch between versions of a PluginDefinition. Also staged rollouts are supported, by enabling Organizations to use the tool/methodology/etc. of their choice to deploy resoruces into their Greenhouse namespace.    |                                                                                                                                                                                                                                                                | 
| Pinning of PluginDefinition versions | +++    | Good, because the PluginDefinition version can be specified. With PluginDefinitionRevisions the configuration of a specific version of a PluginDefinition is configured.    |
| Rollbacks on failure | +    | Good, because it is possible to switch to an older version of a PluginDefinition. Changes to a Plugin should be tracked in git and it is possible to revert to an ealier version. This requires that the previous version of the PluginDefinition is still available. Changes to the HelmChart that potentially break on a rollback cannot be adressed. |
| Staged Rollouts | +++    | Good, because the Plugin Admins of an Organization can decide how/when to update the Plugins. By managing the Greenhouse resources in a git repository, it will also be possible to have 4-eyes approval etc. on changes.|


### [option 5]

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
