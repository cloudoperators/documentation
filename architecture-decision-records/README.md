# Architecture decision record (ADR)

This folder contains Architecture decision records (ADRs) for the Operations Platform.  
The purpose is to provide transparency and enable a broader team to contribute to various aspects.

## Conventions

### Template

Use the [ADR template](0_template.md).

### Illustrations

Use [mermaid](https://www.mermaidchart.com/app/dashboard) within the markdown files for technical illustrations instead of external assets.

### Naming

The files should be named using this conventions `<component>-ADR-<number>-<name>.md`.  
The `<number>` consists of 3 digits. Use leading zeros if necessary.  
The `CloudOperators` component is used for ADRs of general nature.   

Example:
* `Greenhouse-ADR-001-logical_authorization_concept_for_plugins.md`
* `CloudOperators-ADR-<number>-<name>.md`

### Contributing

Each ADR should live on a dedicated branch and be proposed through a pull request (PR).  
Decision contributors are to be assigned as `reviewers` to the PR.  
An ADR is accepted, once all reviewers approved the PR. 