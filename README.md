# Data Integration of INCENTIVE non-omics Datasets

One of the goals of the INCENTIVE project was an integrated dataset
across all the assays performed on the samples collected in the
trials. The construction of the CSV versions of all the datasets was
aimed, in part, at promoting this integrated dataset both in the
structure of the long-format, CSV file as well as the use of a
[Controlled Vocabulary](https://github.com/INCENTIVE-Grant/Controlled-Vocabulary)
for terms within that file.

There are aspects of the data that are not included in this integrated
set.  For example, the urea-containing samples used for computing
avidity in the [Dobaño Lab
dataset](https://github.com/INCENTIVE-Grant/Dobano-Aguilar_Antigen-Specific-Antibodies)
are excluded.

### Log file contents

The log file, initially `buildIntegratedDataset_2026-03-26.log`,
provides valuable information for a data analyst who wishes to know
the exact contents of every column. The `table()` function of R is
applied to each column of the integrated data set to show the strings
used across the whole dataset.

## Limitations of the integrated dataset

While the data have been cleaned, they have been left relatively
'raw', largely as _median fluorescence intensity_ (MFI). While there
are arguments that analysis is best performed on data in its raw
state, most people would prefer to work with the data adjusted by
standard curves into concentrations where possible. Additionally, the
computation of items like _avidity_ could be valuable as well.

The data to perform these conversions is usually available in the CSV
files, but has not been applied for this dataset integration.

## Creation of the integrated dataset

There seems little reason to keep a copy of the integrated dataset at
this time as it is so easy to create it when needed from the original
CSV files.

The set up for perparing the dataset is a directory which contains
this code. In addition the CSV files from the datasets that one wishes
to include need to reside in the same directory.

```
## Set up the directory with this code
git clone git@github.com:INCENTIVE-Grant/Data-Integration.git

## Enter the Data Integration directory
cd Data-Integration

## Download the Zenodo CSV data files and move into this directory
mv ~/Downloads/*.csv ./

## Run the buildIntegration program (via Rscript)
./buildIntegratedDataset.R

## If the program reports "Completed", it ran without errors.
## Examine the log to confirm successful run.
more buildIntegratedDataset_YYYYMMDD.log

## The dataset is named 'buildIntegratedDataset_YYYYMMDD.csv
## and is ready for use.
```
