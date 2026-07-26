# Quarto Codespaces

[![Dev Container Docker Image Build](https://github.com/mcanouil/quarto-codespaces/actions/workflows/devcontainer.yml/badge.svg?event=release)](https://github.com/mcanouil/quarto-codespaces/actions/workflows/devcontainer.yml)[![Codespaces Prebuilds](https://github.com/mcanouil/quarto-codespaces/actions/workflows/codespaces/create_codespaces_prebuilds/badge.svg)](https://github.com/mcanouil/quarto-codespaces/actions/workflows/codespaces/create_codespaces_prebuilds)

[GitHub Codespaces](https://github.com/features/codespaces) and [Development Containers](https://containers.dev/) with [Quarto](https://quarto.org/), R, Python, and Julia, ready to render.
The image carries the Quarto CLI, R with `renv`, Python with `uv` and Jupyter, Julia with `IJulia`, TinyTeX for PDF output, and headless Chrome or Chromium for screenshots and Decktape.

**Documentation: <https://m.canouil.dev/quarto-codespaces>**

## Open a Codespace

Purpose-built image ([`ghcr.io/mcanouil/quarto-codespaces:latest`](https://github.com/mcanouil/quarto-codespaces/pkgs/container/quarto-codespaces)), fastest to start:  
[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/mcanouil/quarto-codespaces?quickstart=1&devcontainer_path=.devcontainer%2Fdevcontainer.json)

Codespaces universal base image, lighter on GitHub storage quota:  
[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/mcanouil/quarto-codespaces?quickstart=1&devcontainer_path=.devcontainer%2Funiversal%2Fdevcontainer.json)

## Use the image

```sh
docker pull ghcr.io/mcanouil/quarto-codespaces:latest
```

| Tag | Quarto | Architectures |
| --- | --- | --- |
| `latest` | stable release | `amd64`, `arm64` |
| `release`, `release-noble` | stable release | `amd64`, `arm64` |
| `prerelease`, `prerelease-noble` | prerelease | `amd64`, `arm64` |
| one per Quarto minor version, with a `-noble` variant | that minor version | `amd64` |
| any tag with a `-<YYYYMMDDHHMM>` suffix | as above, pinned to one build | as above |

Images are rebuilt every Sunday and scanned with [Trivy](https://trivy.dev/).
Full tag list: [`ghcr.io/mcanouil/quarto-codespaces`](https://github.com/mcanouil/quarto-codespaces/pkgs/container/quarto-codespaces).

## Use as a Dev Container

```json
{
  "name": "My Quarto project",
  "image": "ghcr.io/mcanouil/quarto-codespaces:latest",
  "remoteUser": "vscode",
  "features": {
    "ghcr.io/rocker-org/devcontainer-features/quarto-cli:1": {
      "version": "release"
    }
  }
}
```

Configurations for the Quarto prerelease and for every supported Quarto minor version are in [`.devcontainer/`](.devcontainer), and listed on the [configurations](https://m.canouil.dev/quarto-codespaces/reference/configurations.html) page.
Click **Use this template** to start your own repository from this one.

## Documentation

- [Getting started](https://m.canouil.dev/quarto-codespaces/getting-started/): Codespaces, local Dev Containers, and template use.
- [Configurations](https://m.canouil.dev/quarto-codespaces/reference/configurations.html): every `devcontainer.json` in the repository.
- [Container images](https://m.canouil.dev/quarto-codespaces/reference/images.html): tags, architectures, build schedule, scanning.
- [Dev Container features](https://m.canouil.dev/quarto-codespaces/reference/features.html): the features built here.
- [`init-env.sh`](https://m.canouil.dev/quarto-codespaces/reference/init-env.html): project-local R, Python, and Julia environments.
- [Quarto check output](https://m.canouil.dev/quarto-codespaces/reference/quarto-check.html): what the latest builds report.

## Contributing

Contributions are welcome.
Open an [issue](https://github.com/mcanouil/quarto-codespaces/issues) or a [pull request](https://github.com/mcanouil/quarto-codespaces/pulls).
See [contributing](https://m.canouil.dev/quarto-codespaces/contributing.html) for the repository layout and what continuous integration checks.

## Licence

MIT.
See [LICENSE](LICENSE).
