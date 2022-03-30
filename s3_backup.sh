#!/usr/bin/env bash

# Author: Michael Grace <mg38@sanger.ac.uk>

DIR=/lustre/scratch119/humgen/teams/hgi/genestack/backups
COPY_DIR=/hgi/backup

PATH=/software/hgi/installs/anaconda3/envs/hgi_base/bin:$PATH

cd $DIR

echo Making Buckets Public
gs-public >/dev/null

for bucket in "genestackupload" "genestackuploadtest"; do

    mkdir -p .s3_backup_$bucket

    echo Syncing $bucket

    RCLONE_OUT=$(rclone sync -v --stats-one-line s3:$bucket .s3_backup_$bucket 2>&1 | tail -2)
    echo $RCLONE_OUT

    if [[ $(echo $RCLONE_OUT | grep '0 Bytes') == "" ]]; then
        echo "Something's different for $bucket - let's create a new tarball"
        
        FNAME=$(date -u '+%Y%m%d%H%M%S').$bucket.tar.gz
        tar -czf $FNAME .s3_backup_$bucket/*

        echo Created $DIR/$FNAME

        COPY_NAME=latest-genestack-s3-backup.$bucket.tar.gz
        cp $FNAME $COPY_DIR/$COPY_NAME
        
        echo Copied to $COPY_DIR/$COPY_NAME
    else
        echo No Changes for $bucket
    fi

done

if [[ $(find . -maxdepth 1 -type f -mtime -6 | wc -l) -ge 6 ]]; then
    echo "We've got at least 6 backups from the last 6 months"
    echo "We're going to delete backups from older than 6 months"
    /usr/bin/find . -maxdepth 1 -type f -mtime +6 -delete
else
    echo "We don't have 6 backups from the last 6 months"
    echo "We're not going to delete any of the older backups"
fi

cd -

echo Making Buckets Private
gs-private >/dev/null

chmod -R o-rwx $DIR

