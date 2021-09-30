#!/usr/bin/bash

if [ "$#" -ne "4" ]; then
  echo -e "\nusage: sh $0 <path of inputfile> <outfile_prefix> <outdir> <thread>\n" 
  echo -e "e.g. sh $0 vs/*virus.fa votu clstr 10\n"
    exit 2
fi

fa=$1
outf=$2
outd=$3
thread=$4

mkdir $outd
cat $fa > $outd/raw.fa
cd $outd

makeblastdb -in raw.fa -out raw.fa -dbtype nucl
seqkit split2 -p $thread raw.fa 

echo "blastn and combine"
for i in `find raw.fa.split/*fa`
do
{
blastn -query $i -db raw.fa -out $i.bt -outfmt 6 -evalue 1e-10 -num_alignments 999999 -word_size 20 -num_threads 10
perl /home/guorc/bin/blast_cvg.v1.pl $i.bt $i.cvg 85 200
#echo $i
}&
done
wait

cat raw.fa.split/*fa.bt > raw.fa.bt
cat raw.fa.split/*fa.cvg > raw.cvg
rm raw.fa.split -rf

/share/data2/guorc/script/fasta_length -i raw.fa |sort -rnk2 > raw.fa.sort.len
blast_cluster.v2.pl raw.fa.sort.len raw.cvg $outf.i95_c75.uniq 75 95
grep '^0' raw.i95_c75.uniq | perl -ne '/>(\S+\d+)/ ;print "$1\n"' |seqkit grep -f - raw.fa > $outf.fa

#/share/data2/guorc/Software/conda/checkv/bin/checkv end_to_end -d /share/data2/guorc/Software/conda/checkv/checkv-db-v0.6/ -t 20 $outf.fa $outf.ckv
#bowtie2-buiild $outf.fa $outf.fa
