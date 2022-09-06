set -ex
mkdir -p /tmp/cran/web/packages
rsync -rptlzv --delete cran.r-project.org::CRAN/web/packages/ /tmp/cran/web/packages
aws s3 sync /tmp/cran s3://$SYNC_BUCKET
