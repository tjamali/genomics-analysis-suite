# Genomics Analysis Suite

## Overview

This repository hosts a collection of computational pipelines and tools for the analysis of **Oxford Nanopore sequencing data**, with a primary emphasis on **RNA sequencing and base modification detection**. The suite integrates independent but complementary subprojects that enable custom basecalling, modification-aware training, and end-to-end RNA analysis workflows. Collectively, these tools are intended to facilitate the study of epigenetic and transcriptomic regulation in health and disease.

---

## Subprojects

### [Nanopore Caller](./nanopore_caller)

The **NanoporeCaller** project focuses on the development of a **custom neural-network–based basecaller** capable of distinguishing methylated from unmethylated bases in Nanopore sequencing data.

* Builds upon existing frameworks such as **Bonito** (Python) and **Dorado** (C++).
* Accepts raw nanopore signals (`pod5`) and generates aligned outputs (`BAM`, `SAM`, `CRAM`).
* Designed to support **epigenetic profiling** of healthy versus cancerous samples.

---

### [Remora Training Pipeline](./remora_training_pipeline)

The **Remora Training Pipeline** provides a structured workflow for training **Remora models** using canonical and modified RNA datasets.

* Automates dataset preparation, basecalling with **Dorado**, and supervised model training with **Remora**.
* Designed for execution in **high-performance computing environments** with GPU acceleration.
* Supports flexible specification of experimental groups, base modifications, and computational resources.

---

### [RNA Pipeline](./rna_pipeline)

The **RNA Pipeline** offers an **end-to-end RNA sequencing analysis framework** for Nanopore data.

* Implements partitioning of `.pod5` files to handle large datasets.
* Executes basecalling (**Dorado**), alignment (**Minimap2**), and modification extraction (**Modkit**).
* Employs cluster-based job scheduling to enable scalable processing of transcriptomic datasets.

---

## Dependencies and Computational Environment

Across the subprojects, the following dependencies recur:

* **Core tools**: Dorado (≥ v0.8.0), Minimap2 (≥ v2.28), Samtools (≥ v1.12), Modkit (≥ v0.4.1).
* **Python packages**: `pod5`, `ont-remora`, and supporting libraries.
* **Job scheduling**: Pipelines are designed for use with a cluster scheduler (e.g., `qsub` on SCC).
* **GPU acceleration**: CUDA-enabled environments are required for efficient basecalling and model training.

Each subproject specifies its own environment setup instructions.

---

## Purpose and Scope

This suite is intended for **research groups engaged in transcriptomic and epigenomic analysis** using Oxford Nanopore sequencing. By combining custom basecalling, model training, and general-purpose pipelines, the repository provides a foundation for:

* Development of **modification-aware basecallers**,
* Training of **custom neural architectures** for RNA modification detection, and
* Deployment of **scalable analysis workflows** for large RNA sequencing datasets.

---

## Citation

If you make use of these tools in your research, please cite the relevant subproject(s). 

## Contact

For any issues or questions regarding the Remora Training Pipeline, please contact:

**Author:** Tayeb Jamali  
**Email:** tjamali.official\@gmail.edu

**Date:** 2025-1-7
