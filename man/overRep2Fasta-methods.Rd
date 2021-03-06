% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/overRep2Fasta.R
\docType{methods}
\name{overRep2Fasta}
\alias{overRep2Fasta}
\alias{overRep2Fasta,ANY-method}
\alias{overRep2Fasta,FastqcData-method}
\alias{overRep2Fasta,FastqcDataList-method}
\title{Write fasta of Over-Represented sequences.}
\usage{
overRep2Fasta(x, path, n = 10, labels, noAdapters = TRUE, ...)

\S4method{overRep2Fasta}{ANY}(x, path, n = 10, labels, noAdapters = TRUE, ...)

\S4method{overRep2Fasta}{FastqcData}(x, path, n = 10, labels, noAdapters = TRUE, ...)

\S4method{overRep2Fasta}{FastqcDataList}(x, path, n = 10, labels, noAdapters = TRUE, ...)
}
\arguments{
\item{x}{Can be a \code{FastqcData} or \code{FastqcDataList}}

\item{path}{Path to export the fasta file to. Reverts to a default in the
working directory if not supplied}

\item{n}{The number of sequences to output}

\item{labels}{An optional named factor of labels for the file names.
All filenames must be present in the names.
File extensions are dropped by default.}

\item{noAdapters}{logical. Remove any sequences identified as possible
adapters or primers by FastQC}

\item{...}{Used to pass any alternative patterns to remove from the end of
filenames}
}
\value{
Exports to a fasta file, and returns the fasta information invisibly
}
\description{
Output overrepresented sequences to disk in fasta format.
}
\details{
Fasta will contain \code{Filename}, \verb{Possible Source},
\verb{Percent of total reads}
}
\examples{

# Get the files included with the package
packageDir <- system.file("extdata", package = "ngsReports")
fl <- list.files(packageDir, pattern = "fastqc.zip", full.names = TRUE)

# Load the FASTQC data as a FastqcDataList object
fdl <- FastqcDataList(fl)

# Export the top10 Overrepresented Sequences as a single fasta file
faOut <- file.path(tempdir(), "top10.fa")
overRep2Fasta(fdl, path = faOut)

}
