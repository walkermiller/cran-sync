mkdir /tmp/cran
rsync -rptlzv --delete cran.r-project.org::CRAN /tmp/cran
aws s3 sync /tmp/cran $SYNC_BUCKET
