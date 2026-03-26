#!/usr/bin/env Rscript
##
## Quick program to try to integrate CSV data sets and
## confirm the correct distribution of variables.
##
## Usage:
##    ./buildIntegratedData.R
## in the same directory as the CSV file exist (or are linked). All CSV files
## in the current working directory are bound (via rbind() ) into a single
## data-frame which is then written to a CSV output file. A crude data file
## selector (i.e. if(infile == 'this') { prepare this way } etc is used to
## make the input files compatible with each other.
##
## VERSION HISTORY
## [2025-12-01 MeD] Initial version
##
##********************************************************************************
## Libraries
library(AnalysisHeader)
library(tools)

Program <- 'buildIntegratedDataset.R'
Version <- 'v1.2.1'

options(warn=1, width=132)

StartTime <- Sys.time()
Today <- format(StartTime, "_%Y-%m-%d")
rootName <- gsub('\\.R', '', Program)
outFile <- paste0(rootName, Today, ".csv")
logFile <- paste0(rootName, Today, ".log")

if( !interactive() ) {
    cat("\n*** Redirecting program reporting to Log File:", logFile, "\n")
    Log <- file(logFile, open='wt')
    sink(Log)
    sink(Log, type='message')
}

## "Pretty" lines for dividing the output - double-header or single-header
dhLine <- paste(rep('=', length=(getOption('width')-2)), collapse='')
shLine <- paste(rep('-', length=(getOption('width')-2)), collapse='')

## Capture the run-time information, including I/O file names
runInfo <- collectRunInfo(programName=Program, version=Version)
print(runInfo)

cat("Log file is:\t", logFile, "\n")
cat("Output file is:\t", outFile, "\n")

##----------------------------------------------------------------------
## Guess at input files based on file extension of ".csv".
## Typically, I do a soft-link (Linux) of the final uploaded
## CSV files in the local directory.
inFiles <- list.files(pattern='\\.csv$')

## Don't integrate the already integrated dataset
grepPattern <- paste0('^', rootName, '_')
cat("Excluded Input File Pattern =", grepPattern, "\n")
inx <- grepl(grepPattern, inFiles)
droppedFiles <- 'None'   # Expect this to be replaced if sum(inx) > 0
if(sum(inx) > 0) {
    droppedFiles <- inFiles[inx]
    inFiles <- inFiles[ !inx ]
}
cat("Input files are:\n\t",
    paste(inFiles, collapse='\n\t'), "\n\n", sep='')
cat("Excluded files:\n\t",
    paste(droppedFiles, collapse='\n\t'), "\n\n", sep='')

##----------------------------------------------------------------------
## Create nicknames from the file names via truncation at HYPHEN
nNames <- gsub('^([^-]*)-.*$', '\\1', inFiles)
cat(shLine, "\nFile nicknames are:\n")
print(data.frame(File=inFiles, Nickname=nNames), row.names=FALSE)

## Read in the files into a list, naming list elements via nicknames
cat(dhLine, "\nRead in the datasets into RAM in list 'dat[]'.\n")
dat <- list()
for(i in 1:length(inFiles)) {
    cat("\tReading:", inFiles[i], "\n")
    dat[[ nNames[i] ]] <- read.csv(inFiles[i], header=TRUE, as.is=TRUE)
    cat("\t\tChecksum:", md5sum(inFiles[i]), "\n")
}

## Display the concordance of the column naming
cat("\n", shLine, "\nColumn naming in the multiple datasets:\n")
for(nm in nNames) {
    cat(nm, "\n\t", paste(colnames(dat[[nm]]), collapse=', '), "\n", sep='')
}

## Processing for each item - special adjustments etc.
## FIXME: Consider not making a fake Isotype column but
##        instead modify the "Assay" from "SpAb" to "Isotype-SpAb".
##        Then, not Isotype column is needed and we're more
##        consistent with the Marchant dataset.
cat("\n", shLine, "\nAdjust datasets for integration:\n")
for(nm in nNames) {
    cat("\tAdjusting:", nm, "\n")

    ## Only retain "Samples"
    cat("\t\tSelection of only SampleType 'Samp'.\n")
    dat[[nm]] <- dat[[nm]][ dat[[nm]]$SampleType == 'Samp', ]

    ## Processing that is specific to each dataset
    if(nm == 'Cox') {
        cat("\t\tDrop column 'SubAssay'\n")
        ## Drop columns that are not needed: SubAssay
        dat[[nm]] <- dat[[nm]][, 1:11]

        ## Need Dobaño Isotype column so add column to Cox data as NA
        cat("\t\tAdd 'fake' Isotype column full of NA.\n")
        dat[[nm]]$Isotype <- NA
    }
    if(nm == 'Dobaño') {
        ## FIXME: I keep wondering if I'd be better off with the
        ## Dobaño data using the trick I used with Guzmán, that is,
        ## combining the assay name "SpecAb" for "Specific Antibody",
        ## with the Isotype, e.g. "SpAb-IgM", and dropping the Isotype
        ## column.
        cat("\t\tDrop rows that have 'UreaPresent' as TRUE.\n")
        ## Drop rows that have 'UreaPresent' == TRUE
        dat[[nm]] <- dat[[nm]][ dat[[nm]]$UreaPresent == FALSE, ]

        ## Drop columns that are not needed
        cat("\t\tDrop columns:", paste(colnames(dat[[nm]])[ -(1:12) ], collapse=', '), "\n")
        dat[['Dobaño']] <- dat[['Dobaño']][, 1:12]
    }
    if(nm == 'Marchant') {
        ## Drop columns that are not needed
        cat("\t\tDrop columns:", paste(colnames(dat[[nm]])[ -(1:11) ], collapse=', '), "\n")
        dat[['Marchant']] <- dat[['Marchant']][, 1:11]

        ## Need Dobaño Isotype column so add column to Marchant data as NA
        cat("\t\tAdd 'fake' Isotype column full of NA.\n")
        dat[[nm]]$Isotype <- NA
    }
    if(nm == 'Guzmán') {
        ## Drop columns that are not needed

        ## Need to add Dobaño Isotype column, full of NA
        cat("\t\tAdd 'fake' Isotype column full of NA.\n")
        dat[[nm]]$Isotype <- NA
    }
}

## Bind everything together - do it in a loop to generalize, but its bad for RAM
cat(dhLine, "\nBind datasets together into 'd'.\n")
d <- NULL
for(nm in nNames) {
    cat("\tbinding:", nm, "\n")
    d <- rbind(d, dat[[nm]])
}

## Describe basics of 'd'
cat("\nDataset 'd' is", format(nrow(d), big.mark=','), "rows x", ncol(d), "columns.\n")
cat("Total size is", format(unclass(object.size(d)), big.mark=','), "bytes.\n")

## Output the integrated dataset
cat("\nWriting data to:", outFile, "\n")
write.csv(d, outFile, row.names=FALSE)
cat("Checksum of 'd' is", md5sum(outFile), "\n")

## Display some stats
cat(dhLine, "\nSome distributions of the contents of the columns in 'd' are:\n\n")
print(sapply(d[, -c(3,10)], function(y) table(y, useNA='ifany', deparse.level = 0)))

##********************************************************************************
## Close up
EndTime <- Sys.time()
cat(dhLine, "\nCompleted:", format(EndTime, '%Y-%m-%d %H:%M:%S'), "\n")
cat("Elapsed time:", difftime(EndTime, StartTime, units='secs'), "secs.\n")

if( !interactive() ) {
    sink(type='message')
    sink()
}
cat("Completed.\n")
