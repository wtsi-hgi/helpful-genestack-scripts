#!/usr/bin/env bash

# Author: Michael Grace <mg38@sanger.ac.uk>

DIR=/lustre/scratch119/humgen/teams/hgi/genestack/backups
COPY_DIR=/hgi/backup

PATH=/software/hgi/installs/anaconda3/envs/hgi_base/bin:/nfs/users/nfs_m/mercury/genestack:$PATH

log () {
    echo -e "$(date)\t$1\t${@:2}"
}

process_bucket () {
    local bucket=$1

    mkdir -p .s3_backup_$bucket

    log $bucket Syncing from S3 to Lustre

    RCLONE_OUT=$(rclone sync -v --stats-one-line s3:$bucket .s3_backup_$bucket 2>&1 | tail -2)
    log $bucket $RCLONE_OUT

    # Do we make a new tarball?
    if [[ $(echo $RCLONE_OUT | grep '0 Bytes') == "" ]]; then
        log $bucket "Something's different - let's create a new tarball"
        
        FNAME=$(date -u '+%Y%m%d%H%M%S').$bucket.tar.gz
        tar -czf $FNAME .s3_backup_$bucket/*

        log $bucket Created $DIR/$FNAME

        COPY_NAME=latest-genestack-s3-backup.$bucket.tar.gz
        cp $FNAME $COPY_DIR/$COPY_NAME
        
        log $bucket Copied to $COPY_DIR/$COPY_NAME
    else
        log $bucket No Changes - no new tarball created
    fi

    # Do we get rid of any old tarballs?
    if [[ $(find . -maxdepth 1 -type f -mtime -6 -name "*.$bucket.tar.gz" | wc -l) -ge 6 ]]; then
        log $bucket "We've got at least 6 backups from the last 6 months"
        log $bucket "We're going to delete backups from older than 6 months"
        /usr/bin/find . -maxdepth 1 -type f -mtime +6 -name "*.$bucket.tar.gz" -delete
    else
        log $bucket "We don't have 6 backups from the last 6 months"
        log $bucket "We're not going to delete any backups"
    fi
}

cd $DIR

log root Making Buckets Public
gs-public >/dev/null

for bucket in "genestackupload" "genestackuploadtest"; do
    process_bucket $bucket &
done

wait

cd - >/dev/null

log root Making Buckets Private
gs-private >/dev/null

log root Ensuring o-rwx for $DIR
chmod -R o-rwx $DIR

