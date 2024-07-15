# Architecture decision records (ADRs)

This folder contains Architecture decision records (ADRs) for the Operations Platform.  
The purpose is to provide transparency and enable a broader team to contribute to various aspects.

## Illustrations

Use [mermaid](https://www.mermaidchart.com/app/dashboard) within the markdown files for technical illustrations instead
of external assets.

## Development

Pre-requisites:

- Node.js [LTS](https://nodejs.org/en/download/)

**If not already done, install `Log4brains`**

```bash
npm install -g log4brains
```

To create a new ADR interactively, run:

```bash
log4brains adr new
```

- When prompted for `Title of the solved problem and its solution?` Provide a title in the
  format `<number> <component> <name>`

- This will generate a new ADR file in the `architecture-decision-records` folder with a filename in the format
  `<yyyymmdd>-<provided title>.md`

### Rename generated ADR filename

`log4brains` will generate the file with current date as prefix followed by the title provided in the
command `log4brains adr new` separated by `-`

e.g. `20240101-<provided-title>.md`

- Please rename the generated filename to `<number>-<component>-<provided-title>.md`.
- The `<number>` should consists of three digits. Use leading zeros if necessary.
- Component can be one of `greenhouse` | `cloudOperators`.

> The `cloudOperators` component is used for ADRs of general nature.

Example:

- `001-Greenhouse-logical-authorization-concept-for-plugins.md`
- `002-CloudOperators-<name>.md`

## Contributing

Each ADR should live on a dedicated branch and be proposed through a pull request (PR).  
Decision contributors are to be assigned as `reviewers` to the PR.  
An ADR is accepted, once all reviewers approved the PR.

## More information

- [Log4brains documentation](https://github.com/thomvaill/log4brains/tree/master#readme)
- [What is an ADR and why should you use them](https://github.com/thomvaill/log4brains/tree/master#-what-is-an-adr-and-why-should-you-use-them)
- [ADR GitHub organization](https://adr.github.io/)
