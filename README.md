# bmlabs Helm charts

Public Helm charts maintained by [bmlabs](https://github.com/bmlabseu).

## Usage

```sh
helm repo add bmlabs https://bmlabseu.github.io/charts
helm repo update
helm search repo bmlabs
```

Charts are also published as OCI artifacts:

```sh
helm install my-site oci://ghcr.io/bmlabseu/charts/classicpress
```

## Charts

| Chart | Description |
| --- | --- |
| [classicpress](charts/classicpress) | ClassicPress, a lightweight fork of WordPress 4.9 |

## Contributing

1. Change a chart under `charts/`.
2. Bump the chart `version` in its `Chart.yaml` (SemVer).
3. Open a pull request. CI runs `ct lint`, renders the chart against several
   Kubernetes versions with `kubeconform`, and installs it into kind.

Merging to `main` releases every chart whose version changed, to both the
GitHub Pages Helm repository and GHCR.

### Automation

| Workflow | What it does |
| --- | --- |
| `lint-test` | Lints, renders and installs changed charts on pull requests |
| `release` | Publishes changed charts to GitHub Pages and GHCR on merge |
| `update-classicpress` | Daily check for a new ClassicPress version, opens a PR |
| `bump-chart-version` | Bumps the chart version on Renovate and Dependabot branches |

Dependabot keeps the GitHub Actions up to date; Renovate keeps the container
images referenced by the charts up to date.

## License

[Apache 2.0](LICENSE)
