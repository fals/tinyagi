#!/bin/bash
set -e

echo "=========================================="
echo "  TinyAGI Sandbox Startup"
echo "=========================================="

TINYAGI_HOME=${TINYAGI_HOME:-/home/agent/tinyagi-workspace}
TINYAGI_PORT=${TINYAGI_API_PORT:-3777}
TINYOFFICE_PORT=${TINYOFFICE_PORT:-3555}
TINYAGI_DIR=/home/agent

mkdir -p "$TINYAGI_HOME/logs"
mkdir -p "$TINYAGI_HOME/chats"
mkdir -p "$TINYAGI_HOME/files"

echo "TINYAGI_HOME: $TINYAGI_HOME"
echo "API Port: $TINYAGI_PORT"
echo "TinyOffice Port: $TINYOFFICE_PORT"

if [ ! -f "$TINYAGI_HOME/settings.json" ]; then
	echo "Creating default settings.json..."
	cat >"$TINYAGI_HOME/settings.json" <<'SETTINGS_EOF'
{
  "workspace": {
    "path": "/home/agent/tinyagi-workspace"
  },
  "agents": {
    "tinyagi": {
      "name": "TinyAGI Agent",
      "provider": "opencode",
      "model": "ai-enabler/minimax-m2.5",
      "working_directory": "/home/agent/tinyagi-workspace/agents/tinyagi"
    }
  }
}
SETTINGS_EOF
fi

mkdir -p "$TINYAGI_HOME/agents/tinyagi"

if [ -f "$TINYAGI_DIR/.config/opencode/opencode.json.template" ] && [ ! -f "$TINYAGI_DIR/.config/opencode/opencode.json" ]; then
	if [ -n "$OPENCODE_API_KEY" ]; then
		sed "s/YOUR_API_KEY_HERE/$OPENCODE_API_KEY/g" "$TINYAGI_DIR/.config/opencode/opencode.json.template" >"$TINYAGI_DIR/.config/opencode/opencode.json"
		echo "Generated opencode.json from template"
	fi
fi

echo ""
echo "Starting TinyAGI API server..."
cd "$TINYAGI_DIR"
npm run start -w @tinyagi/main >"$TINYAGI_HOME/logs/tinyagi.log" 2>&1 &
TINYAGI_PID=$!

echo "TinyAGI API PID: $TINYAGI_PID"

echo "Waiting for API to start..."
sleep 5

echo ""
echo "Starting TinyOffice UI..."
cd "$TINYAGI_DIR/tinyoffice"
HOST=0.0.0.0 PORT=$TINYOFFICE_PORT npm run start >"$TINYAGI_HOME/logs/tinyoffice.log" 2>&1 &
TINYOFFICE_PID=$!

echo "TinyOffice PID: $TINYOFFICE_PID"

echo ""
echo "=========================================="
echo "  TinyAGI is running!"
echo "=========================================="
echo "  API:   http://localhost:$TINYAGI_PORT"
echo "  UI:    http://localhost:$TINYOFFICE_PORT"
echo ""
echo "  Logs:"
echo "    API:   $TINYAGI_HOME/logs/tinyagi.log"
echo "    UI:    $TINYAGI_HOME/logs/tinyoffice.log"
echo "=========================================="

cleanup() {
	echo ""
	echo "Shutting down..."
	kill $TINYAGI_PID 2>/dev/null || true
	kill $TINYOFFICE_PID 2>/dev/null || true
	exit 0
}

trap cleanup SIGINT SIGTERM

wait $TINYAGI_PID $TINYOFFICE_PID
