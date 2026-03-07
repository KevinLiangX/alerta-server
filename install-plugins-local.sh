#!/bin/bash
# Install alerta plugins from local alerta-contrib source.
# Reads docker-alerta/plugins.txt; format per line: "<subdirectory> <ignored>"
# Example: "plugins/slack master"  →  pip install /src/alerta-contrib/plugins/slack

set -e

while read -r plugin _version; do
  # Skip blank lines and comments
  [[ -z "${plugin}" || "${plugin}" == \#* ]] && continue
  local_path="/src/alerta-contrib/${plugin}"
  if [ -d "${local_path}" ]; then
    echo "Installing '${plugin}' from local source: ${local_path}"
    /venv/bin/pip install --no-cache-dir "${local_path}"
  else
    echo "WARNING: plugin directory not found, skipping: ${local_path}"
  fi
done </app/plugins.txt
