# M. tuberculosis Variant Calling Pipeline

Whole-genome sequencing analysis of a *Mycobacterium tuberculosis* clinical isolate to detect genetic variants and predict drug resistance using standard bioinformatics tools.

---

## Background

*Mycobacterium tuberculosis* is the causative agent of tuberculosis (TB). It is a leading infectious disease responsible for approximately 10.4 million cases globally in 2016, including 490,000 multidrug-resistant TB (MDR-TB) cases (WHO, 2017). Its ability to persist and develop resistance to antibiotics makes it important to study at the genomic level.

The H37Rv strain (NC_000962.3) is the standard reference genome for *M. tuberculosis*. Whole-genome sequencing (WGS) of clinical isolates allows comparison against this reference to identify variants that may contribute to drug resistance.

Resistance-associated genes include:
- katG, inhA → isoniazid  
- rpoB → rifampicin  
- embB, embC → ethambutol  
- pncA → pyrazinamide  
- rpsL, rrs → streptomycin  
(Dookie et al., 2018) 
---

## Dataset

- Reference genome: H37Rv (*M. tuberculosis*), NC_000962.3 (NCBI RefSeq)
- Sequencing reads: SRR38742949 (paired-end Illumina, NCBI SRA)
- Clinical isolate: TX-DSHS-MTB-2600584 (Texas Department of State Health Services)

---

## Pipeline

### 1. Download reads

```bash
prefetch SRR38742949
fastq-dump --split-files SRR38742949.sra
```

---

### 2. Quality control

```bash
fastqc SRR38742949_1.fastq SRR38742949_2.fastq
```

FastQC showed generally high base quality with a slight drop toward the 3’ ends and minor early-cycle bias. No significant adapter contamination was observed.

---

### 3. Trimming

```bash
trimmomatic PE -phred33 \
SRR38742949_1.fastq SRR38742949_2.fastq \
SRR38742949_1_paired.fastq SRR38742949_1_unpaired.fastq \
SRR38742949_2_paired.fastq SRR38742949_2_unpaired.fastq \
ILLUMINACLIP:TruSeq3-PE.fa:2:30:10 \
LEADING:3 TRAILING:3 SLIDINGWINDOW:4:20 MINLEN:50
```

Only paired reads were retained for downstream analysis.

---

### 4. Alignment

```bash
bwa index H37Rv_ref_sequence.fasta

bwa mem H37Rv_ref_sequence.fasta \
SRR38742949_1_paired.fastq \
SRR38742949_2_paired.fastq > output.sam
```

---

### 5. SAM/BAM processing

```bash
samtools view -bS output.sam > output.bam
samtools sort output.bam -o output_sorted.bam
samtools index output_sorted.bam
```

---

### 6. Variant calling

```bash
bcftools mpileup -f H37Rv_ref_sequence.fasta output_sorted.bam -o output.bcf
bcftools call -mv -Ov -o variants.vcf output.bcf
grep -v '^#' variants.vcf | wc -l
```

Approximately 1,200 variant sites were identified relative to the reference genome.

---

### 7. Resistance profiling

Variant annotation and drug resistance interpretation were performed using TB-Profiler (v6.7.0, database version: 7fe4364e) via the web interface.

---

### 8. Visualization

BAM and VCF files were loaded into IGV for manual inspection of key loci (e.g. rpoB, gyrA) to validate variant calls.

---

## Results

Sequencing quality: 98.11% of reads mapped to H37Rv with median coverage of 82x. 

Variants identified: 1,219 variants detected relative to H37Rv.

Lineage: 4.6.3 (Euro-American family, 100% frequency).

Drug resistance: No confirmed resistance-associated mutations were detected across all analyzed drugs including rifampicin, isoniazid, ethambutol, pyrazinamide, and streptomycin. The isolate is predicted susceptible.

Non-associated variants: Several variants were identified within known resistance candidate genes — including gyrA, rpsL, rrs, and embC. However, none corresponded to mutations currently classified as resistance-conferring in the TB-Profiler WHO v2+ database (Database version: 7fe4364e). 

**Figure 1:** IGV genome overview showing variant distribution across the *Mycobacterium tuberculosis* genome.



<img width="1436" height="898" alt="overview" src="https://github.com/user-attachments/assets/837b5e8a-5d3a-4292-9454-524c484049c7" />


 **Figure 2:** Zoomed IGV view of a non-resistance associated variant in *gyrA*, confirmed at read level.

 
 
 <img width="1440" height="900" alt="3" src="https://github.com/user-attachments/assets/982bd336-b2d6-4422-9cab-d8876228a2bf" />


 
 

 **Figure 3:** Read coverage at the *rpoB* locus with no variant calls, consistent with rifampicin susceptibility.

 

 <img width="1440" height="900" alt="rpob" src="https://github.com/user-attachments/assets/585843f0-bbc2-47b5-a9e6-e019d966acc0" />
 



### TB-Profiler summary 
<img width="1253" height="631" alt="tbprofiler_summary" src="https://github.com/user-attachments/assets/2f162768-3fb9-43d9-a039-9a6498b6b64d" />


---

## Conclusions and Limitations

This analysis identified 1,219 genomic variants in a clinical M. tuberculosis isolate relative to H37Rv. TB-Profiler predicted the isolate to be drug susceptible with no confirmed resistance mutation. 

Some variants were found in resistance-associated genes, but they were classified as non-associated or of uncertain significance.

**Limitations:**

Variant calling was performed using bcftools without additional filtering steps. TB-Profiler was run via the web interface rather than command line due to a version compatibility issue on macOS (KeyError: invalid FORMAT: AD). Future work would include cross-referencing variants against ReSeqTB for more comprehensive clinical interpretation. 

---

## Software used

| Tool | Version |
|------|---------|
| FastQC | 0.12.1 |
| Trimmomatic | 0.40 |
| BWA | 0.7.19-r1273 |
| samtools | 1.23.1 |
| bcftools | 1.23.1 |
| TB-Profiler | 6.7.0 |

---

## References

1. WHO Global Tuberculosis Report 2017  
2. Phelan et al. (2019). Integrating informatics tools and portable sequencing technology for rapid detection of resistance to anti-tuberculous drugs. *Genome Medicine*, 11, 41.  
3. ReSeqTB Platform — Critical Path Institute  
4. Anthony M. Bolger, Marc Lohse, Bjoern Usadel. Trimmomatic: a flexible trimmer for Illumina sequence data. *Bioinformatics*, Volume 30, Issue 15, August 2014, pp. 2114–2120. https://doi.org/10.1093/bioinformatics/btu170  
5. Petr Danecek et al. Twelve years of SAMtools and BCFtools. *GigaScience*, Volume 10, Issue 2, 2021, giab008. https://doi.org/10.1093/gigascience/giab008  
6. Li H. (2013). Aligning sequence reads, clone sequences and assembly contigs with BWA using the Burrows–Wheeler transform (BWA-MEM). arXiv:1303.3997v2 
6. Dookie, N., Rambaran, S., Padayatchi, N., Mahomed, S., & Naidoo, K. (2018). Evolution of drug resistance in Mycobacterium tuberculosis: a review on the molecular determinants of resistance and implications for personalized care. Journal of Antimicrobial Chemotherapy, 73(5), 1138–1151. https://doi.org/10.1093/jac/dkx506 



