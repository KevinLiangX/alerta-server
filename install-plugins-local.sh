#!/bin/bash
# Install alerta plugins from local alerta-contrib source.
# Reads /app/plugins.txt; format per line: "<subdirectory> <ignored>"
# Example: "plugins/slack master"  →  pip install /src/alerta-contrib/plugins/slack

FAILED=()

while read -r plugin _version; do
  # Skip blank lines and comments
  [[ -z "${plugin}" || "${plugin}" == \#* ]] && continue
  local_path="/src/alerta-contrib/${plugin}"
  if [ -d "${local_path}" ]; then
    echo "------------------------------------------------------------"
    echo "Installing '${plugin}' from: ${local_path}"
    if /venv/bin/pip install --no-cache-dir "${local_path}"; then
      echo "OK: ${plugin}"
    else
      echo "FAILED: ${plugin}"
      FAILED+=("${plugin}")
    fi
  else
    echo "WARNING: plugin directory not found, skipping: ${local_path}"
  fi
done </app/plugins.txt

echo "============================================================"
if [ ${#FAILED[@]} -eq 0 ]; then
  echo "All plugins installed successfully."
else
  echo "The following plugins failed to install:"
  for p in "${FAILED[@]}"; do echo "  - ${p}"; done
  exit 1
fi
