#!/usr/bin/env bash
# Syncs the chart's appVersion with the ClassicPress version baked into the
# upstream image, and bumps the chart patch version when it changes.
set -euo pipefail

CHART_DIR="${1:-charts/classicpress}"
CHART_FILE="$CHART_DIR/Chart.yaml"
DOCKERFILE_URL="https://raw.githubusercontent.com/ClassicPress/docker-images/main/php8.3/Dockerfile"

emit() {
  echo "$1=$2"
  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    echo "$1=$2" >> "$GITHUB_OUTPUT"
  fi
}

upstream="$(curl -fsSL "$DOCKERFILE_URL" \
  | sed -n "s/^[[:space:]]*version='\([0-9][^']*\)';.*/\1/p" | head -n1)"

if [[ -z "$upstream" ]]; then
  echo "could not determine the ClassicPress version from $DOCKERFILE_URL" >&2
  exit 1
fi

current="$(yq -r '.appVersion' "$CHART_FILE")"

if [[ "$current" == "$upstream" ]]; then
  emit updated false
  emit version "$upstream"
  exit 0
fi

chart_version="$(yq -r '.version' "$CHART_FILE")"
IFS=. read -r major minor patch <<< "$chart_version"
next_chart_version="$major.$minor.$((patch + 1))"

export NEW_APP_VERSION="$upstream"
export NEW_CHART_VERSION="$next_chart_version"
export CHANGES="- kind: changed
  description: Update ClassicPress to $upstream
"

yq -i '
  .appVersion = strenv(NEW_APP_VERSION) |
  .version = strenv(NEW_CHART_VERSION) |
  .annotations."artifacthub.io/changes" = strenv(CHANGES)
' "$CHART_FILE"

emit updated true
emit version "$upstream"
emit previous_version "$current"
emit chart_version "$next_chart_version"
