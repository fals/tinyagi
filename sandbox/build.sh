#!/bin/bash
set -e

REGISTRY=${1:-localhost:5001}
IMAGE_NAME=${2:-tinyagi-sandbox}
TAG=${3:-latest}

TINYAGI_ROOT=/Users/fals/projects/tinyagi
SANDBOX_DIR="$TINYAGI_ROOT/sandbox"
BUILD_DIR=$(mktemp -d)

echo "Building TinyAGI Sandbox Image"
echo "================================"
echo "Registry: $REGISTRY"
echo "Image: $IMAGE_NAME:$TAG"
echo ""

trap "rm -rf $BUILD_DIR" EXIT

echo "Creating TinyAGI archive..."
cd "$TINYAGI_ROOT"
tar czf "$BUILD_DIR/tinyagi.tar.gz" \
	--exclude='node_modules' \
	--exclude='.git' \
	--exclude='.sbx' \
	--exclude='*.log' \
	--exclude='.env' \
	--exclude='.env.local' \
	--exclude='dist' \
	--exclude='.next' \
	--exclude='package-lock.json' \
	packages/ tinyoffice/ package.json tsconfig*.json README.md SOUL.md AGENTS.md

cp "$SANDBOX_DIR/Dockerfile" "$BUILD_DIR/"
cp "$SANDBOX_DIR/entrypoint.sh" "$BUILD_DIR/"
cp "$SANDBOX_DIR/opencode.json.template" "$BUILD_DIR/"

echo "Building Docker image..."
docker build -t "$REGISTRY/$IMAGE_NAME:$TAG" "$BUILD_DIR"

echo ""
echo "Pushing to registry..."
docker push "$REGISTRY/$IMAGE_NAME:$TAG"

echo ""
echo "================================"
echo "Done! Image available at:"
echo "  $REGISTRY/$IMAGE_NAME:$TAG"
echo ""
echo "To run with API key:"
echo "  docker run -d --name tinyagi -p 3777:3777 -p 3555:3555 -e OPENCODE_API_KEY=your_key $REGISTRY/$IMAGE_NAME:$TAG"
echo "================================"
