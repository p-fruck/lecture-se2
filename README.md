# Lecture: Software Engineering 2

[![CC BY 4.0][cc-by-shield]][cc-by]
![Deploy Pages](https://github.com/p-fruck/lecture-se2/actions/workflows/pages.yml/badge.svg)

Goal: Focus more on Git and GitOps (Pipelines, Container, K8s?) than on traditional software engineering

## Usage

All slides are located in the [slides](slides) folder and written using Markdown.
[presenterm](https://github.com/mfontanini/presenterm) and mermaid CLI are required for local rendering.

Run `just` to get an overview of all usable commands.
`just present slides/00-introduction.md` will launch the presenter slide.

For slides containing images, a terminal emulator like [kitty or foot](https://mfontanini.github.io/presenterm/features/images.html) must be used.
When running inside `tmux`, you need to `set allow-passthrough` for image rendering to work.

## Notes

TODO: Consider Tools like Claper

- Questions
  - Which programming languages?
  - What are students most interested in?
- Git
  - commits
  - branches
  - clone/pull/push (ssh vs https)
  - rebase
  - merge
  - squash
  - Strategy (feat -> dev -> main)
  - config (split into multiple files)
  - gitignore
    - `git check-ignore`
  - README (markdown)
  - folder structure (opinionated)
  - commit signing (ssh + gpg)
  - commit messages (conventional commits, branch naming)
  - diff (delta)
  - bisec
- GitOps
  - Pipelines (act)
  - Maybe GitLab?
  - check (format), lint, test, build, deploy
- Containers
  - Podman/Docker
  - Containerfiles, multi-staging
    - scratch/distroless?
  - .dockerignore
  - Versioning (semantic versions)
  - Compose?
  - k8s definitions
  - k8s deployment using flux?

## License

This work is licensed under a
[Creative Commons Attribution 4.0 International License][cc-by].

[![CC BY 4.0][cc-by-image]][cc-by]

[cc-by]: http://creativecommons.org/licenses/by/4.0/
[cc-by-image]: https://i.creativecommons.org/l/by/4.0/88x31.png
[cc-by-shield]: https://img.shields.io/badge/License-CC%20BY%204.0-lightgrey.svg
