
```bash
.
├── analysis # Sequencing data
│   ├── benchmarking/ # Human reference samples used
│   ├── hg001/ # Files divided by each individual
│   │   ├── hac/
│   │   └── sup/ # Sequence file results for each nanopore run, seperated by pass and fail
│   │        ├── PAO83395.fail.cram
│   │        ├── PAO83395.fail.cram.crai
│   │        ├── PAO83395.pass.cram
│   │        ├── PAO83395.pass.cram.crai
│   │        ├── PAO89685.fail.cram
│   │        ├── PAO89685.fail.cram.crai
│   │        ├── PAO89685.pass.cram
│   │        └── PAO89685.pass.cram.crai
│   ├── hg002/
│   ├── hg003/
│   ├── hg004/
│   ├── small_variants_happy/
│   │   ├── hg001_hac_60x_happy_out/
│   │   ├── hg001_sup_60x_happy_out/
│   │   .
│   ├── stats/
│   │   ├── hac_PAO83395.cram.stats
│   │   ├── hac_PAO89685.cram.stats
│   │   .
│   ├── variant_calling/ #data for variants specific to each individual
│   │   ├── hg001_hac_60x/
│   │   ├── hg001_hac_all/
│   │   ├── hg001_sup_60x/
│   │   ├──hg001_sup_all/
│   │   .
│   └── DS_Store/
└── flowcells/ # nanopore data
    ├── hg001/ # files divided by each individual
    ├── hg002/
    ├── hg003/
    └── hg004/ # Contains folders of seperate nanopore runs
        ├── 20230424_1302_3H_PAO89685_2264ba8c # Contains all data related to each nanopore runs
        ├── 20230428_1310_3H_PAO89685_c9d0d53f
        ├── 20230429_1600_2E_PAO83395_124388f5
        └── 20230503_1206_2E_PAO83395_ba06e1bb
            ├── other_reports/ # Nanopore machine related data (temperature, porescan data)
            ├── pod5_fail/ # Contains .pod5 files that don't meet predetermined accuracy threshold
            ├── pod5_pass/ # Contains .pod5 files that meet predetermined accuracy threshold
            ├── barcode_alignment_PAO89685_2264ba8c_afee3a87.tsv
            ├── final_summary_PAO89685_2264ba8c_afee3a87.txt
            ├── full_ss_every_17.txt
            ├── pore_activity_PAO89685_2264ba8c_afee3a87.csv
            ├── read_list.txt
            ├── report_PAO89685_20230424_1308_2264ba8c.html
            ├── report_PAO89685_20230424_1308_2264ba8c.json
            ├── report_PAO89685_20230424_1308_2264ba8c.md
            ├── sample_sheet_PAO89685_20230424_1308_2264ba8c.csv
            └── sequencing_summary_PAO89685_2264ba8c_afee3a87.txt throughput_PAO89685_2264ba8c_afee3a87.csv
```
