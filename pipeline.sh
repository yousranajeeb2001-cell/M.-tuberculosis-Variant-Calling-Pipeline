#!/bin/bash 

# 1. Download reads
prefetch SRR38742949
fastq-dump --split-files SRR38742949.sra

# 2. QC
fastqc SRR38742949_1.fastq SRR38742949_2.fastq

# 3. Trim
trimmomatic PE -phred33 \
SRR38742949_1.fastq SRR38742949_2.fastq \
SRR38742949_1_paired.fastq SRR38742949_1_unpaired.fastq \
SRR38742949_2_paired.fastq SRR38742949_2_unpaired.fastq \
ILLUMINACLIP:TruSeq3-PE.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:20 MINLEN:50

# 4. Alignment
bwa index H37Rv_ref_sequence.fasta
bwa mem H37Rv_ref_sequence.fasta SRR38742949_1_paired.fastq SRR38742949_2_paired.fastq > output.sam

# 5. SAM/BAM
samtools view -bS output.sam > output.bam
samtools sort output.bam -o output_sorted.bam
samtools index output_sorted.bam

# 6. Variant calling
bcftools mpileup -f H37Rv_ref_sequence.fasta output_sorted.bam -o output.bcf
bcftools call -mv -Ov -o variants.vcf output.bcf

