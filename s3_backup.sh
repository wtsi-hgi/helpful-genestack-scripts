#!/usr/bin/env bash

# This script is for us to backup our Genestack S3 buckets

# It uses a copy of the data in lustre to know what has already
# been backed up, so it recognises when there is different data

# This is tarballed and stored on lustre, with the most recent backup
# also being saved in IRODS.

# Author: Michael Grace <mg38@sanger.ac.uk>

source /usr/local/lsf/conf/profile.lsf
set -euo pipefail

# Directory in Lustre where the backups are controlled from
# This script creates and deletes directories and files
# in here so ideally nothing else should use this directory
DIR=/lustre/scratch119/humgen/teams/hgi/genestack/backups

# Path in IRODS where the most recent backup is copied to
# This script creates and deletes things here, so nothing
# else should be stored in this area
IRODS_LOC=/humgen/teams/hgi/genestack-backups

PATH=/software/hgi/installs/anaconda3/condabin:/software/hgi/installs/anaconda3/envs/hgi_base/bin:/nfs/users/nfs_m/mercury/genestack:$PATH

log () {
    # log a message along with timestamp and part
    # of this script that is calling it
    echo -e "$(date)\t$1\t${@:2}"
}

submit_jobs_cpu_count () {
    # submits a farm job
    # the first argument is the number of cpus
    # to request, and the remaining arguments are the
    # command to run

    # to reduce issues with escaping strings, and
    # variables, we write the command to a file and
    # call that file

    # this function prints the job ID given
    
    local new=.tmp/$RANDOM$RANDOM$RANDOM
    echo ${@:2} > $new

    bsub -o .tmp/%J -e .tmp/%J -G hgi -n $1 bash $new | awk -F '<|>' '{print $2}'
}

submit_job () {
    # submits a farm job with a cpu request of 1
    # this is just a layer of abstraction, so only
    # the command needs providing if calling this
    # function

    submit_jobs_cpu_count 1 ${@}
}

view_job_output() {
    # waits for the given job id to finish, and then
    # shows that jobs output

    # NOTE: this doesn't view job output
    # in real time, only once it has finished

    local JOB_ID=$1
    
    while true; do
        sleep 5
        [[ $(bjobs | grep $(whoami) | awk -v job_id="$JOB_ID" -F ' ' '{if ($1 == job_id) {print}}') == "" ]] && break
    done

    cat .tmp/$JOB_ID
}

process_bucket () {
    # This is the main fun part of this script
    # For each bucket, we're going to:
    # 1. Sync it to Lustre
    # 2. If something's different:
    # 2. a) Write a file listing files over 5GB we aren't including
    # 2. b) Submit a farm job to tarball it all up
    # 2. c) Submit a farm job to split it into 10GB chunks
    # 2. d) Submit a farm job to sync the split files to IRODS
    # 2. e) Delete any extra files from IRODS
    # 3. If there's at least 6 backups of this bucket from the last 6 months,
    #   delete any backups for this bucket older than 6 months

    local bucket=$1

    # Syncing S3 to Lustre
    mkdir -p .s3_backup_$bucket

    log $bucket Syncing from S3 to Lustre

    local RCLONE_OUT=$(rclone sync -v --stats-one-line s3:$bucket .s3_backup_$bucket 2>&1 | tail -2)
    log $bucket $RCLONE_OUT

    # Do we make a new tarball?
    if [[ $(echo $RCLONE_OUT | grep '0 Bytes') == "" ]]; then
        log $bucket "Something's different - let's create a new tarball"
        
        # Let's look at what we're not including (anything over 5GB)
        echo Excluding These Files - They are Over 5GB > .s3_backup_$bucket/BACKUP_README
        find .s3_backup_$bucket -size +5G >> .s3_backup_$bucket/BACKUP_README

        local FNAME=$(date -u '+%Y%m%d%H%M%S').$bucket.tar.gz
        
        # Make the original tarball
        # (this is a wonderful yet also horrific command)
        local JOB_ID=$(submit_job \(find .s3_backup_$bucket -size +5G -exec echo --exclude={} \\\;\; echo '-czf' $DIR/$FNAME .s3_backup_$bucket\) \| xargs tar)

        log $bucket Tarball Job - $JOB_ID
        view_job_output $JOB_ID

        /bin/rm .s3_backup_$bucket/BACKUP_README

        log $bucket Created $DIR/$FNAME

        # Let's Split It Up (into 10GB chunks for IRODS)
        mkdir .tmp_tar.$bucket
        local JOB_ID=$(submit_job split -b 10G -d $FNAME .tmp_tar.$bucket/$bucket.tar.gz.)
        
        log $bucket Split Job - $JOB_ID
        view_job_output $JOB_ID

        # Sync it to IRODS
        imkdir -p $IRODS_LOC/$bucket
        local JOB_ID=$(submit_jobs_cpu_count 4 irsync -rK -N 4 .tmp_tar.$bucket i:$IRODS_LOC/$bucket)

        log $bucket IRODS Sync Job - $JOB_ID
        view_job_output $JOB_ID
        
        # Delete Old Files from IRODS
        for irods_file in $(ils $IRODS_LOC/$bucket | tail +2); do
            [[ -f .tmp_tar.$bucket/$irods_file ]] || (irm $IRODS_LOC/$bucket/$irods_file && log $bucket Deleted $irods_file from IRODS)
        done

        /bin/rm -r .tmp_tar.$bucket
    else
        log $bucket No Changes - no new tarball created
    fi

    # Do we get rid of any old tarballs?
    # We keep the last 6 backups or 6 months worth of backups - whichever's more
    if [[ $(find . -maxdepth 1 -type f -mtime -6 -name "*.$bucket.tar.gz" | wc -l) -ge 6 ]]; then
        log $bucket "We've got at least 6 backups from the last 6 months"
        log $bucket "We're going to delete backups from older than 6 months"
        /usr/bin/find . -maxdepth 1 -type f -mtime +6 -name "*.$bucket.tar.gz" -delete -print
    else
        log $bucket "We don't have 6 backups from the last 6 months"

        if [[ $(ls -1 *.$bucket.tar.gz | wc -l) -ge 6 ]]; then
            log $bucket "We've got at least 6 backups though, so we'll just keep those"
            for f in $(ls -1t *.$bucket.tar.gz | tail +7); do
                echo $bucket Deleting $f
                /bin/rm $f
            done
        else
            log $bucket "We haven't even got 6 backups in total"
            log $bucket "We're not going to delete any"
        fi
    fi
}

cd $DIR
mkdir -p .tmp

log root Making Buckets Public
gs-public > /dev/null

for bucket in "genestackupload" "genestackuploadtest"; do
    # Run the processing for each bucket at the same time
    process_bucket $bucket &
done

wait

# Tidying Up
/bin/rm -r .tmp
cd - > /dev/null

log root Making Buckets Private
gs-private > /dev/null

log root Ensuring o-rwx for $DIR
chmod -R o-rwx $DIR

log root Done
