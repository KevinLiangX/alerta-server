#!/bin/bash
# Build the allinone Docker image from local source (frontend + backend + plugins).
#
# Usage:
#   ./build-allinone.sh                          # Build linux/amd64 + linux/arm64, push to registry
#   ./build-allinone.sh --load                   # Build linux/amd64 only, load to local docker (for local testing)
#   REGISTRY=my.registry.io ./build-allinone.sh  # Override registry
#
# Environment variables:
#   REGISTRY   - Image registry prefix (default: alerta-custom)
#   IMAGE_NAME - Full image name without tag (default: ${REGISTRY})
#   PLATFORMS  - Comma-separated platform list (default: linux/amd64,linux/arm64)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Config ────────────────────────────────────────────────────────────────────
REGISTRY="${REGISTRY:-}"
BASE_NAME="alerta-custom"
IMAGE_NAME="${IMAGE_NAME:-${REGISTRY:+${REGISTRY}/}${BASE_NAME}}"
PLATFORMS="${PLATFORMS:-linux/amd64,linux/arm64}"

VERSION=$(cat "${SCRIPT_DIR}/alerta/VERSION" 2>/dev/null || echo "dev")
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
VCS_REF=$(git -C "${SCRIPT_DIR}/alerta" rev-parse --short HEAD 2>/dev/null || echo "local")

# ── Parse args ────────────────────────────────────────────────────────────────
LOAD_MODE=false
for arg in "$@"; do
  case "$arg" in
    --load)
      LOAD_MODE=true
      PLATFORMS="linux/amd64"  # --load only supports single platform
      ;;
  esac
done

echo "========================================"
echo "  Building alerta allinone image"
echo "  Image:    ${IMAGE_NAME}"
echo "  Version:  ${VERSION}"
echo "  Revision: ${VCS_REF}"
echo "  Platform: ${PLATFORMS}"
echo "  Load:     ${LOAD_MODE}"
echo "========================================"

# ── Ensure buildx builder exists ─────────────────────────────────────────────
if ! docker buildx inspect multiarch >/dev/null 2>&1; then
  echo "Creating buildx builder 'multiarch'..."
  docker buildx create --name multiarch --use
  docker buildx inspect --bootstrap
else
  docker buildx use multiarch
fi

# ── Build ─────────────────────────────────────────────────────────────────────
BUILD_ARGS=(
  --platform "${PLATFORMS}"
  -f "${SCRIPT_DIR}/Dockerfile.allinone"
  --build-arg "BUILD_DATE=${BUILD_DATE}"
  --build-arg "RELEASE=${VERSION}"
  --build-arg "VERSION=${VCS_REF}"
  -t "${IMAGE_NAME}:latest"
  -t "${IMAGE_NAME}:${VERSION}"
)

if [ "${LOAD_MODE}" = true ]; then
  BUILD_ARGS+=(--load)
  echo "[local test mode] Building single-platform image and loading to local Docker..."
else
  if [ -z "${REGISTRY}" ]; then
    echo "WARNING: REGISTRY is not set. Use --load for local testing, or set REGISTRY= for push."
    BUILD_ARGS+=(--load)
    PLATFORMS="linux/amd64"
  else
    BUILD_ARGS+=(--push)
  fi
fi

docker buildx build "${BUILD_ARGS[@]}" "${SCRIPT_DIR}"

echo ""
echo "Done! Image: ${IMAGE_NAME}:${VERSION} / ${IMAGE_NAME}:latest"

if [ "${LOAD_MODE}" = true ] || [ -z "${REGISTRY}" ]; then
  echo ""
  echo "Quick test:"
  echo "  docker run --rm \\"
  echo "    -e DATABASE_URL=postgres://postgres:postgres@host.docker.internal:5432/monitoring \\"
  echo "    -e AUTH_REQUIRED=False \\"
  echo "    -p 8080:8080 \\"
  echo "    ${IMAGE_NAME}:latest"
fi
