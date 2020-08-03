// Import generic module functions
include { initOptions; saveFiles } from './functions'

process SAMTOOLS_SORT {
    tag "$meta.id"
    label 'process_medium'
    publishDir "${params.outdir}/${options.publish_dir}${options.publish_by_id ? "/${meta.id}" : ''}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename, options, task.process.tokenize('_')[0].toLowerCase()) }
        
    container "quay.io/biocontainers/samtools:1.10--h9402c20_2"
    //container " https://depot.galaxyproject.org/singularity/samtools:1.10--h9402c20_2"

    conda (params.conda ? "bioconda::samtools=1.10" : null)

    input:
    tuple val(meta), path(bam)
    val options

    output:
    tuple val(meta), path("*.bam"), emit: bam
    path "*.version.txt", emit: version

    script:
    def software = task.process.tokenize('_')[0].toLowerCase()
    def ioptions = initOptions(options, software)
    prefix = ioptions.suffix ? "${meta.id}${ioptions.suffix}" : "${meta.id}"
    """
    samtools sort $ioptions.args -@ $task.cpus -o ${prefix}.bam -T $prefix $bam
    echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//' > ${software}.version.txt
    """
}
