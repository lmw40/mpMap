% Generated by roxygen2 (4.0.2): do not edit by hand
\name{sim.mpcross}
\alias{sim.mpcross}
\title{Simulate data from multi-parent designs}
\usage{
sim.mpcross(map, pedigree, qtl = NULL, vare = 1, error.prob = 0,
  missing.prob = 0, full.prob = 0, keep.qtlgeno = TRUE,
  transpos = integer(0), transFounder = 0, map.function = c("haldane",
  "kosambi"), seed = 1, fg = NULL, founderld = FALSE, het.call.prob = 0)
}
\arguments{
\item{map}{Linkage map with which to generate data. See \code{\link[qtl]{sim.map}}}

\item{pedigree}{Pedigree for a multi-parent cross. Can be generated using \code{\link[mpMap]{sim.mpped}}}

\item{qtl}{QTL model, defined by a matrix with one row per QTL and 6 columns: the chromosome of the QTL, the position in cM on that chromosome, and the four founder effects}

\item{vare}{Phenotypic error variance}

\item{error.prob}{Probability of genotyping errors - data will be changed with this probability to one of the other founder values}

\item{missing.prob}{Probability of missing data in final genotypes}

\item{full.prob}{Probability of fully informative markers. Markers will be assigned with this probability to retain IBD genotypes from founders rather than being recoded into binary values. See details below for more information}

\item{keep.qtlgeno}{Flag for whether to retain the QTL genotypes as a component in the output \code{mpcross} object}

\item{transpos}{Positions of potential translocation (vector)}

\item{transFounder}{Which founder carries the translocation}

\item{map.function}{Map function for conversion of linkage map into recombination fractions. Default is "haldane"}

\item{seed}{Random seed for generation of data}

\item{fg}{Input founder genotypes (optional) - otherwise generated randomly}

\item{founderld}{Flag for whether to generate founder genotypes in linkage equilibrium (FALSE=default) or according to recombination map (TRUE)}

\item{het.call.prob}{The proportion of hets which are correctly called. Non-called hets are marked as NA.}
}
\value{
Object of class \code{mpcross}. See \code{\link[mpMap]{mpcross}} for further details. Additional components are:
\item{ibd}{ Fully informative founder genotypes for all markers}
\item{qtlgeno}{ If argument \code{keep.qtlgeno} is \code{TRUE} then QTL genotypes will be retained}
}
\description{
Data is simulated according to a pedigree, map and QTL model
}
\details{
If any of the QTL are located precisely at a marker, that marker is removed at the start. Data are initially generated by transmitting founder genotypes down through the pedigree to the finals. Binary alleles are then overlaid on this data (stored in $ibd). Errors are then added if necessary. Any allele chosen to be an error is selected uniformly from the alternative possibilities. Alleles are combined to give a single genotype at each marker. A certain proportion \code{het.call.prob} of hetrozygotes are retained, the rest are marked as NA. Finally, missing data is added according to \code{missing.prob}.

If founderld==FALSE, binary alleles are generated independently at each locus. The founders with the allele are randomly selected after the number of founders with the allele has been simulated. If founderld==TRUE then some markers may be monomorphic and will need to be removed from the resulting object using \code{\link[mpMap]{clean.mpcross}}.

Note that if founder genotypes are input they should be coded as follows:
DArT markers take values in {0,1}
SNP markers take values in {0,2}
All other markers take some other set of values.
}
\note{
Translocations can only be generated when founderld==FALSE and no founder genotypes are input. Note that founder effects in the QTL model are per allele; thus, the phenotypic difference between a line carrying the founder and one that is not will be twice the input founder effect (because all lines are inbred).
}
\examples{
map <- sim.map(len=100, n.mar=11, eq.spacing=TRUE, include.x=FALSE)
sim.ped <- sim.mpped(4, 1, 500, 6, 1)
sim.dat <- sim.mpcross(map=map, pedigree=sim.ped, qtl=matrix(data=c(1, 50, .4, 0, 0, 0), nrow=1, ncol=6, byrow=TRUE), seed=1)
}
\seealso{
\code{\link[mpMap]{sim.mpped}}, \code{\link[qtl]{sim.map}}
}

