// Import generic module functions
include { initOptions; saveFiles } from './functions'

process PICARD_MERGESAMFILES {
    tag "$meta.id"
    label 'process_medium'
    publishDir "${params.outdir}/${options.publish_dir}${options.publish_by_id ? "/${meta.id}" : ''}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename, options, task.process.tokenize('_')[0].toLowerCase()) }

    container "quay.io/biocontainers/picard:2.23.2--0"
    //container "https://depot.galaxyproject.org/singularity/picard:2.23.2--0"

    conda (params.conda ? "bioconda::picard=2.23.2" : null)

    input:
    tuple val(meta), path(bams)
    val options

    output:
    tuple val(meta), path("*.bam"), emit: bam
    path "*.version.txt", emit: version

    script:
    def software = task.process.tokenize('_')[0].toLowerCase()
    def ioptions = initOptions(options, software)
    prefix = ioptions.suffix ? "${meta.id}${ioptions.suffix}" : "${meta.id}"
    bam_files = bams.sort()
    def avail_mem = 3
    if (!task.memory) {
        log.info '[Picard MergeSamFiles] Available memory not known - defaulting to 3GB. Specify process memory requirements to change this.'
    } else {
        avail_mem = task.memory.giga
    }
    if (bam_files.size() > 1) {
        """
        picard \\
            -Xmx${avail_mem}g \\
            MergeSamFiles \\
            $ioptions.args \\
            ${'INPUT='+bam_files.join(' INPUT=')} \\
            OUTPUT=${prefix}.bam
        echo \$(picard MergeSamFiles --version 2>&1) | awk -F' ' '{print \$NF}' > ${software}.version.txt
        """
    } else {
        """
        ln -s ${bam_files[0]} ${prefix}.bam
        echo \$(picard MergeSamFiles --version 2>&1) | awk -F' ' '{print \$NF}' > ${software}.version.txt
        """
    }
}
