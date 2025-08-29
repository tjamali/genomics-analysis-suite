module load miniconda 
conda activate nanopore 

ROOT="/restricted/projectnb/leshlab/net/tjamali/project"
INPUT_POD5="${ROOT}/remora_dataset/subset/5mC_rep2.pod5"
INPUT_BAM="${ROOT}/remora_dataset/basecalls/5mC_rep2.bam"  # this is the bam file obtained using dorado basecalling
MODEL="${ROOT}/remora_output/training_results/model_best.pt"
OUTPUT_BAM="${ROOT}/remora_output/inference_results/5mC_rep2_modcalls.bam"
OUTPUT_LOG="${ROOT}/remora_output/inference_results/5mC_rep2_modcalls.log"

MOD_TYPE="5mC"
PORE_TYPE="dna_r10.4.1_e8.2_400bps"

# remora infer from_pod5_and_bam $INPUT_POD5 $INPUT_BAM --model $MODEL --out-bam $OUTPUT_BAM --log-filename $OUTPUT_LOG --device 0

remora infer from_pod5_and_bam $INPUT_POD5 $INPUT_BAM --modified-bases $MOD_TYPE --pore $PORE_TYPE --out-bam $OUTPUT_BAM --log-filename $OUTPUT_LOG --device 0
