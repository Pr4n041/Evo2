#!/bin/bash
#SBATCH --job-name=taxonomy_prompt
#SBATCH --output=taxonomy_prompt_%j.log
#SBATCH --error=taxonomy_prompt_%j.err
#SBATCH --time=00:10:00
#SBATCH --partition=cpu_batch
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: sbatch $0 \"Species name\" [output_file]"
  exit 1
fi

SPECIES_NAME="$1"
OUTPUT_FILE="${2:-taxonomy_prompt.txt}"

PROMPT=$(SPECIES_NAME="$SPECIES_NAME" python - <<'PY'
import os
import sys

from evo2.utils import make_phylotag_from_gbif

species_name = os.environ["SPECIES_NAME"].strip()
if not species_name:
    print("Species name must not be empty", file=sys.stderr)
    raise SystemExit(1)

try:
    prompt = make_phylotag_from_gbif(species_name)
except Exception as exc:
    print(f"Failed to generate taxonomy prompt for '{species_name}': {exc}", file=sys.stderr)
    raise SystemExit(1)

if not isinstance(prompt, str) or not prompt.strip():
    print(f"No taxonomy prompt generated for '{species_name}'", file=sys.stderr)
    raise SystemExit(1)

print(prompt.strip())
PY
)

printf '%s\n' "$PROMPT" | tee "$OUTPUT_FILE"
echo "Wrote taxonomy-based prompt to $OUTPUT_FILE"
