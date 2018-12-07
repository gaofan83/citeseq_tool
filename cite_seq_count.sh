#!/bin/bash
READ_CELL_INDEX="cell_index.fastq.gz"
READ_FEATURE_INDEX="feature_index.fastq.gz"
BC_START=1
BC_LENGTH=16
UMI_START=17
UMI_LENGTH=9
TAG="ADT.txt"
OUTPUT="cite_count.txt"
THREAD=8

function usage()
{
    echo "./cite_seq_count.sh [options]"
    echo "-h --help"
    echo "Please specify the following options:"
    echo "-fqc --fastq_cell=$READ_CELL_INDEX   [gzipped fastq R1 or R2 for cell index reads]"
    echo "-fqf --fastq_feature=$READ_FEATURE_INDEX   [gzipped fastq R1 or R2 for feature index reads]"
    echo "-it --input_tag=$TAG   [feature tag sequence file; one sequence per line, start with >; e.g., ATATCT tag should be written as >ATATCT]"
    echo "-bcs --bc_start=$BC_START   [start position of cell barcode in cell index reads]"
    echo "-bcl --bc_length=$BC_LENGTH   [length of cell barcodes in cell index reads]"
    echo "-umis --umi_start=$UMI_START   [start position of unique molecular identifiers in cell index reads; if not available, use 0]"
    echo "-umil --umi_length=$UMI_LENGTH   [length of unique molecular identifiers in cell index reads; if not available, use 0]"
    echo "-t --threads=$THREAD [number of threads to use]"
    echo "-o --output=$OUTPUT   [output file name]"
    echo ""
    echo "Example below:"
    echo "bash cite_seq_count.sh -fqc=SRR5808750_1.fastq.gz -fqf=SRR5808750_2.fastq.gz -it=ADT.txt -bcs=1 -bcl=16 -umis=17 -umil=9 -t=8 -o=SRR5808750_count.txt"
}

while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        -h | --help)
            usage
            exit
            ;;
        -fqc |--fastq_cell)
            READ_CELL_INDEX=$VALUE
            ;;
        -fqf |--fastq_feature)
            READ_FEATURE_INDEX=$VALUE
            ;;
        -it |--input_tag)
            TAG=$VALUE
            ;;
        -bcs | --bc_start)
            BC_START=$VALUE
            ;;
        -bcl | --bc_length)
            BC_LENGTH=$VALUE
            ;;
        -umis | --umi_start)
            UMI_START=$VALUE
            ;;
        -umil | --umi_length)
            UMI_LENGTH=$VALUE
            ;;
        -t | --threads)
            THREAD=$VALUE
            ;;
        -o |--output)
            OUTPUT=$VALUE
            ;;
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            usage
            exit 1
            ;;
    esac
    shift
done

echo "READ_CELL_INDEX is $READ_CELL_INDEX";
echo "READ_FEATURE_INDEX is $READ_FEATURE_INDEX";
echo "TAG is $TAG";
echo "BC_START is $BC_START";
echo "BC_LENGTH is $BC_LENGTH";
echo "UMI_START is $UMI_START";
echo "UMI_LENGTH is $UMI_LENGTH";
echo "THREAD is $THREAD";
echo "OUTPUT is $OUTPUT";

N=$THREAD
# Paste R1/R2 fasta sequence records 
mkdir -p temp
echo "Finished process" > temp/log
paste <(zcat $READ_CELL_INDEX) <(zcat $READ_FEATURE_INDEX) | awk '{if('NR%4==2') print $1">"$2}' > temp/temp.fa

run_adt(){
	pattern=$1
	BC_START=$2
        BC_LENGTH=$3
	UMI_START=$4
	UMI_LENGTH=$5
	#add polyA tail pattern for cite-seq feature reads
	EXT="[GCT]AAAAAAAAAAAAAAAAAAAAAAAA"
	echo "Processing feature index $pattern now..."
	#one mismatch in feature index allowed
	awk -v mypattern="$pattern" -v ext="$EXT" 'BEGIN { for (i=2; i<= length(mypattern); i++) print substr(mypattern,1,i-1)"."substr(mypattern,i+1)ext}' > temp/temp.$pattern
	grep --line-buffered -f temp/temp.$pattern temp/temp.fa | awk -v bc_start="$BC_START" -v bc_len="$BC_LENGTH" -v umi_start="$UMI_START" -v umi_len="$UMI_LENGTH" '{print substr($0, bc_start, bc_len)"-"substr($0, umi_start, umi_len)}' > temp/temp.BC_UMI.$pattern
	sort temp/temp.BC_UMI.$pattern | uniq | cut -c $BC_START-$BC_LENGTH > temp/temp.BC.$pattern
	sort temp/temp.BC.$pattern | uniq -c | awk -v myline="$1" '{print $2"\t"myline"\t"$1}' > temp/count.$pattern
	echo "$pattern is complete" >> temp/log
}

while read line;
do
  ((i=i%N)); ((i++==0)) && wait
  run_adt "$line" "$BC_START" "$BC_LENGTH" "$UMI_START" "$UMI_LENGTH" &
done < $TAG

wait

cat temp/count* > $OUTPUT
