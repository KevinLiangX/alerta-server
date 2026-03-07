#!/bin/bash
# Install alerta plugins from local alerta-contrib source.
# Reads /app/plugins.txt; format per line: "<subdirectory> <ignored>"
# Example: "plugins/slack master"  →  pip install /src/alerta-contrib/plugins/slack
#
# Plugin install failures are NON-FATAL: a warning is printed and the build continues.
# Check the summary at the end to see which plugins (if any) need attention.

FAILED=()

while read -r plugin _version; do
  # Skip blank lines and comments
  [[ -z "${plugin}" || "${plugin}" == \#* ]] && continue
  local_path="/src/alerta-contrib/${plugin}"
  if [ -d "${local_path}" ]; then
    echo "------------------------------------------------------------"
    echo "Installing '${plugin}' from: ${local_path}"
    # Capture pip output so failures are fully visible in build logs
    if /venv/bin/pip install --no-cache-dir "${local_path}" 2>&1; then
      echo "OK: ${plugin}"
    else
      echo "WARNING: pip install failed for '${plugin}' (see output above) — skipping"
      FAILED+=("${plugin}")
    fi
  else
    echo "WARNING: plugin directory not found, skipping: ${local_path}"
    FAILED+=("${plugin} [dir missing]")
  fi
done </app/plugins.txt

echo "============================================================"
if [ ${#FAILED[@]} -eq 0 ]; then
  echo "All plugins installed successfully."
else
  echo "WARNING: The following plugins could NOT be installed (non-fatal):"
  for p in "${FAILED[@]}"; do echo "  - ${p}"; done
  echo "The image will still build. Fix the listed plugins before relying on them at runtime."
fi

# Always exit 0 — plugin failures are warnings, not build blockers.
exit 0
