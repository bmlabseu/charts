#!/usr/bin/env bash
# Renders the chart across representative configurations and validates the
# manifests against the Kubernetes schemas.
set -euo pipefail

CHART="${1:-charts/classicpress}"
KUBE_VERSIONS=("1.28.0" "1.31.0" "1.34.0")

cases=(
  "defaults|"
  "external-db|--set mariadb.enabled=false --set database.host=db.example.com --set database.existingSecret=my-db --set database.existingSecretPasswordKey=pw"
  "ingress-tls|--set ingress.enabled=true --set ingress.className=nginx --set ingress.tls[0].secretName=tls --set ingress.tls[0].hosts[0]=cp.example.com"
  "autoscaling|--set autoscaling.enabled=true --set autoscaling.targetMemoryUtilizationPercentage=75 --set podDisruptionBudget.enabled=true"
  "no-persistence|--set persistence.enabled=false --set mariadb.persistence.enabled=false --set serviceAccount.create=false"
  "existing-claims|--set persistence.existingClaim=cp-data --set mariadb.persistence.existingClaim=db-data --set classicpress.existingSecret=cp-salts"
)

for kube in "${KUBE_VERSIONS[@]}"; do
  for entry in "${cases[@]}"; do
    name="${entry%%|*}"
    args="${entry#*|}"
    echo "==> k8s ${kube} / ${name}"
    # shellcheck disable=SC2086
    helm template release "$CHART" --namespace cp --kube-version "$kube" $args \
      | kubeconform -strict -summary -kubernetes-version "$kube" \
          -schema-location default \
          -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json'
  done
done
