# Validate results with modkit

ROOT="/restricted/projectnb/leshlab/net/tjamali/project"
INPUT_BAM="${ROOT}/remora_output/inference_results/5mC_rep2_modcalls.bam"
INPUT_BED="${ROOT}/remora_dataset/references/all_5mers_5mC_sites.bed"
OUTPUT_EVALUATION="${ROOT}/remora_output/inference_results/evaluate_5mC_mods.txt"
OUTPUT_LOG="${ROOT}/remora_output/inference_results/validate_5mC_5hmC_mods.log"

modkit validate \
    --bam-and-bed $INPUT_BAM $INPUT_BED \
    --min-identity 10 \
    --out-filepath $OUTPUT_EVALUATION \
    --log-filepath $OUTPUT_LOG
