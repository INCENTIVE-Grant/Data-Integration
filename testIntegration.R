#!/usr/bin/env Rscript
##
## Quick program to try to integrate CSV data sets and
## confirm the correct distribution of variables.
##
## VERSION HISTORY
## [2025-12-01 MeD] Initial version
##
##********************************************************************************
## Libraries
library(AnalysisHeader)

Program <- 'testIntegration.R'
Version <- 'v1.0'

options(warn=1, width=80)

StartTime <- Sys.time()
Today <- format(StartTime, "%Y-%m-%d")
outFile <- paste0('dataIntegration_', Today, ".csv")
logFile <- paste0('testIntegration_', Today, ".log")

if( !interactive() ) {
    cat("\n*** Redirecting program reporting to Log File:", logFile, "\n")
    Log <- file(logFile, open='wt')
    sink(Log)
    sink(Log, type='message')
}

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
inx <- grepl('^dataIntegration_', inFiles)
if(sum(inx) > 0) {
    droppedFiles <- inFiles[inx]
    inFiles <- inFiles[ !inx ]
}
cat("Input files are:\n\t",
    paste(inFiles, collapse='\n\t'), "\n\n", sep='')
if(1 == 1) {
    cat("\tDropped file:", paste(droppedFiles, collapse=', '), "\n")
}

##----------------------------------------------------------------------
## Create nicknames from the file names via truncation at HYPHEN
nNames <- gsub('^([^-]*)-.*$', '\\1', inFiles)
cat("\nFile nicknames are:\n")
print(data.frame(File=inFiles, Nickname=nNames), row.names=FALSE)

## Read in the files into a list, naming list elements via nicknames
cat("\nRead in the datasets into RAM in list 'dat[]'.\n")
dat <- list()
for(i in 1:length(inFiles)) {
    cat("\tReading:", inFiles[i], "\n")
    dat[[ nNames[i] ]] <- read.csv(inFiles[i], header=TRUE, as.is=TRUE)
}

## Display the concordance of the column naming
cat("\nColumn naming in the multiple datasets:\n")
for(nm in nNames) {
    cat(nm, "\n\t", paste(colnames(dat[[nm]]), collapse=', '), "\n", sep='')
}

## Processing for each item - special adjustments etc.
## FIXME: Consider not making a fake Isotype column but
##        instead modify the "Assay" from "SpAb" to "Isotype-SpAb".
##        Then, not Isotype column is needed and we're more
##        consistent with the Marchand dataset.
cat("\nAdjust datasets for integration:\n")
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
        cat("\t\tDrop rows that have 'UreaPresent' as TRUE.\n")
        ## Drop rows that have 'UreaPresent' == TRUE
        dat[[nm]] <- dat[[nm]][ dat[[nm]]$UreaPresent == FALSE, ]

        ## Drop columns that are not needed
        cat("\t\tDrop columns:", paste(colnames(dat[[nm]])[ -(1:12) ], collapse=', '), "\n")
        dat[['Dobaño']] <- dat[['Dobaño']][, 1:12]
    }
    if(nm == 'Marchand') {
        ## Drop columns that are not needed
        cat("\t\tDrop columns:", paste(colnames(dat[[nm]])[ -(1:11) ], collapse=', '), "\n")
        dat[['Marchand']] <- dat[['Marchand']][, 1:11]

        ## Need Dobaño Isotype column so add column to Marchand data as NA
        cat("\t\tAdd 'fake' Isotype column full of NA.\n")
        dat[[nm]]$Isotype <- NA
    }
}

## Bind everything together - do it in a loop to generalize, but its bad for RAM
cat("\nBind datasets together into 'd'.\n")
d <- NULL
for(nm in nNames) {
    d <- rbind(d, dat[[nm]])
}

## Describe basics of 'd'
cat("\nDataset 'd' is", nrow(d), "rows x", ncol(d), "columns.\n")
cat("Total size is", object.size(d), "bytes.\n")

## Display some stats
cat("\n------------------------------------------------------------\n")
cat("Some distributions of the contents of the columns in 'd' are:\n\n")
print(sapply(d[, -c(3,10)], function(y) table(y, useNA='ifany', deparse.level = 0)))

## Output the integrated dataset
cat("\n------------------------------------------------------------\n")
cat("Writing data to:", outFile, "\n")
write.csv(d, outFile, row.names=FALSE)

##********************************************************************************
## Close up
EndTime <- Sys.time()
cat("\nCompleted:", format(EndTime, '%Y-%m-%d %H:%M:%S'), "\n")
cat("Elapsed time:", difftime(EndTime, StartTime, units='secs'), "secs.\n")

if( !interactive() ) {
    sink(type='message')
    sink()
}
cat("Completed.\n")

## Fixes:
##   Trial == NA in Arnaud's data
##   Day == NA (when?)
##   Strain --> Confirm strains. Check NA in strains. Check Dobaño strains.
##   Protein --> Confirm Cox protein assignment
##
## Confirm the order of columns in the existing data matches that in Controlled-Vocab.R
##

