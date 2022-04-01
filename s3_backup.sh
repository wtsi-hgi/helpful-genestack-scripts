#!/usr/bin/env bash

# Author: Michael Grace <mg38@sanger.ac.uk>

source /usr/local/lsf/conf/profile.lsf
set -euo pipefail

DIR=/lustre/scratch119/humgen/teams/hgi/genestack/backups
IRODS_LOC=/humgen/teams/hgi/genestack-backups

PATH=/software/hgi/installs/anaconda3/envs/hgi_base/bin:/nfs/users/nfs_m/mercury/genestack:$PATH

log () {
    echo -e "$(date)\t$1\t${@:2}"
}

submit_jobs_cpu_count () {
	new=.tmp/$RANDOM$RANDOM$RANDOM
	echo ${@:2} > $new
    bsub -o .tmp/%J -e .tmp/%J -G hgi -n $1 bash $new | awk -F '<|>' '{print $2}'
}

submit_job () {
    submit_jobs_cpu_count 1 ${@}
}

tail_job_output() {
    local JOB_ID=$1

    while true; do
	    [[ $(bjobs | grep $JOB_ID) == "" ]] && break
	    sleep 5
    done

    cat .tmp/$JOB_ID
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

        # Let's look at what we're not including (anything over 5GB)
        echo Excluding These Files - They are Over 5GB > .s3_backup_$bucket/BACKUP_README
        find .s3_backup_$bucket -size +5G >> .s3_backup_$bucket/BACKUP_README

        local FNAME=$(date -u '+%Y%m%d%H%M%S').$bucket.tar.gz
        
        # Make the original tarball
        local JOB_ID=$(submit_job find .s3_backup_$bucket -size +5G -exec echo --exclude={} \\\; \| xargs -I '{}' tar '{}' -czf $DIR/$FNAME .s3_backup_$bucket)

        log $bucket Tarball Job - $JOB_ID
        tail_job_output $JOB_ID

        /bin/rm .s3_backup_$bucket/BACKUP_README

        log $bucket Created $DIR/$FNAME

        # Let's Split It Up
        mkdir .tmp_tar.$bucket
        local JOB_ID=$(submit_job split -b 10G -d $FNAME .tmp_tar.$bucket/$bucket.tar.gz.)

        log $bucket Split Job - $JOB_ID
        tail_job_output $JOB_ID

        # Sync it to IRODS
        imkdir -p $IRODS_LOC/$bucket
        local JOB_ID=$(submit_jobs_cpu_count 4 irsync -rK -N 4 .tmp_tar.$bucket i:$IRODS_LOC/$bucket)

        log $bucket IRODS Sync Job - $JOB_ID
        tail_job_output $JOB_ID

        # Delete Old Files from IRODS
        for irods_file in $(ils $IRODS_LOC/$bucket); do
            [[ -f .tmp_tar.$bucket/$irods_file ]] || irm $IRODS_LOC/$bucket/$irods_file && log $bucket Deleted $irods_file from IRODS
        done

        /bin/rm -r .tmp_tar.$bucket
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
mkdir -p .tmp

log root Making Buckets Public
gs-public > /dev/null

for bucket in "genestackupload" "genestackuploadtest"; do
    process_bucket $bucket &
done

wait

#/bin/rm -r .tmp
cd - > /dev/null

log root Making Buckets Private
gs-private > /dev/null

log root Ensuring o-rwx for $DIR
chmod -R o-rwx $DIR

