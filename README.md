## CITESEQ_tool

#### Inspired by [CITE-seq computational tool] (https://cite-seq.com/computational-tools/), I wrote a BASH tool that can process CITE-seq data.
####
#### Installation guide:
* Install CITESEQ_tool source codes `git clone https://github.com/gaofan83/citeseq_tool.git`.
####
#### Quick run of a demo data:
* Relocate to local citeseq_tool directory:
* `cd citeseq_tool`
* `fastq-dump --split-files SRR5808750`
* `gzip *fastq`
* `bash cite_seq_count.sh -fqc=SRR5808750_1.fastq.gz -fqf=SRR5808750_2.fastq.gz -it=ADT.txt -bcs=1 -bcl=16 -umis=17 -umil=9 -t=8 -o=SRR5808750_count.txt`
