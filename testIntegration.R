inFiles <- list.files(pattern='\\.csv$')
cat("Input files found are:\n\t",
    paste(inFiles, collapse='\n\t'), "\n", sep='')

## Create nicknames from the file names via truncation at HYPHEN
nNames <- gsub('^([^-]*)-.*$', '\\1', inFiles)
cat("\nFile nicknames are:\n\t",
    paste(nNames, collapse='\n\t'), "\n", sep='')

## Read in the files into a list, naming list elements via nicknames
dat <- list()
for(i in 1:length(inFiles)) {
    dat[[ nNames[i] ]] <- read.csv(inFiles[i], header=TRUE, as.is=TRUE)
}

## Display the concordance of the column naming
cat("Column naming in the multiple datasets:\n")
for(nm in nNames) {
    cat(sprintf("%-10s:", nm), paste(colnames(dat[[nm]]), collapse=', '), "\n", sep='')
}

## Processing for each item - special adjustments etc.
for(nm in nNames) {
    ## Only retain "Samples"
    dat[[nm]] <- dat[[nm]][ dat[[nm]]$SampleType == 'Samp', ]

    ## Processing that is specific to each dataset
    if(nm == 'Cox') {
        ## Drop columns that are not needed: SubAssay
        dat[[nm]] <- dat[[nm]][, 1:11]

        ## Need Dobaño Isotype column so add column to Cox data as NA
        dat[[nm]]$Isotype <- NA
    }
    if(nm == 'Dobaño') {
        ## Drop rows that have 'UreaPresent' == TRUE
        dat[[nm]] <- dat[[nm]][ dat[[nm]]$UreaPresent == FALSE, ]

        ## Drop columns that are not needed
        dat[['Dobaño']] <- dat[['Dobaño']][, 1:12]
    }
    if(nm == 'Marchand') {
        ## Drop columns that are not needed
        dat[['Marchand']] <- dat[['Marchand']][, 1:11]

        ## Need Dobaño Isotype column so add column to Marchand data as NA
        dat[[nm]]$Isotype <- NA
    }
}

## Bind everything together - do it in a loop to generalize, but its bad for RAM
d <- NULL
for(nm in nNames) {
    d <- rbind(d, dat[[nm]])
}

## Display some stats
print(sapply(d[, -c(3,10)], function(y) table(y, useNA='ifany', deparse.level = 0)))

## Fixes:
##   Trial == NA in Arnaud's data
##   Day == NA (when?)
##   Strain --> Confirm strains. Check NA in strains. Check Dobaño strains.
##   Protein --> Confirm Cox protein assignment
##
## Confirm the order of columns in the existing data matches that in Controlled-Vocab.R
