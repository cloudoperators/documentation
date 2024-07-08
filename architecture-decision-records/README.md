# Architecture decision record (ADR)

This folder contains Architecture decision records (ADRs) for the Operations Platform.  
The purpose is to provide transparency and enable a broader team to contribute to various aspects.

## Conventions

### Template

Use the [ADR template](0_template.md).

### Naming

The files should be named using this conventions `<component>-ADR-<number>-<name>.md`.
The `CloudOperators` component is used for ADRs of general nature.   
Example:
* `Greenhouse-ADR-1-logical_authorization_concept_for_plugins.md`
* `CloudOperators-ADR-<number>-<name>.md`

### Contributing

Each ADR should live on a dedicated branch and be proposed through a pull request (PR).  
Decision contributors are to be assigned as `reviewers` to the PR.  
An ADR is accepted, once all reviewers approved the PR. 