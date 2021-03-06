% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/importNgsLogs.R
\name{.parseTrimmomaticLogs}
\alias{.parseTrimmomaticLogs}
\title{Parse data from trimmomatic log files}
\usage{
.parseTrimmomaticLogs(data, ...)
}
\arguments{
\item{data}{List of lines read using readLines on one or more files}

\item{...}{not used}
}
\value{
tibble
}
\description{
Parse data from trimmomatic log files
}
\details{
Checks for structure will have been performed
}
\keyword{internal}
