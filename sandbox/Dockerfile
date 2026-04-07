FROM docker/sandbox-templates:shell

USER root

RUN apt-get update && apt-get install -y \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g opencode-ai 2>/dev/null || true

ENV PATH="/usr/local/share/npm-global/bin:$PATH"

USER agent

WORKDIR /home/agent

COPY --chown=agent:agent tinyagi.tar.gz* ./
RUN if [ -f tinyagi.tar.gz ]; then \
    tar -xzf tinyagi.tar.gz && rm tinyagi.tar.gz; \
    fi

RUN mkdir -p tinyagi-workspace

WORKDIR /home/agent

ENV TINYAGI_HOME=/home/agent/tinyagi-workspace
ENV NODE_ENV=production

RUN npm install --include=dev 2>&1 || true

RUN cd tinyoffice && npm install --include=dev 2>&1 || true

RUN cd tinyoffice && npm run build 2>&1 || true

RUN rm -f packages/*/tsbuildinfo tsconfig.tsbuildinfo && npx tsc --build --force 2>&1 || true

RUN mkdir -p /home/agent/tinyagi-workspace/.tinyagi

COPY --chown=agent:agent opencode.json.template /home/agent/.config/opencode/opencode.json.template
RUN sed 's/YOUR_API_KEY_HERE/'${OPEN_CODE_API_KEY:-}/'g' /home/agent/.config/opencode/opencode.json.template > /home/agent/.config/opencode/opencode.json || true

RUN cat > /home/agent/tinyagi-workspace/settings.json << 'EOF'
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
EOF

RUN mkdir -p /home/agent/.npm-global

RUN mkdir -p /home/agent/tinyagi-workspace/agents/tinyagi

COPY --chown=agent:agent entrypoint.sh /home/agent/entrypoint.sh
RUN chmod +x /home/agent/entrypoint.sh

WORKDIR /home/agent

EXPOSE 3777 3555

CMD ["/home/agent/entrypoint.sh"]