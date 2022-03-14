#!/usr/bin/env bash

# Change the Owner of Genestack Studies owned by a User

# Author: Michael Grace <mg38@sanger.ac.uk>

if [ $# -ne 2 ]; then
    echo "usage: change-owner.sh CURRENT_OWNER_EMAIL NEW_OWNER_EMAIL" >&2
    exit 1
fi

yn () {
    while true; do
        read -p "[y/n] " yn
        case $yn in
            [Yy]* ) break;;
            [Nn]* ) exit;;
            * ) echo "Please answer y or n.";;
        esac
    done
}

# Check with the user we're on the right host
tput setaf 3
echo "You are using $(hostname) - are you sure this is right?"
yn

# Check the user knows about access
tput setaf 1
echo "Is the project already shared with the new user $2?? Otherwise they won't be able to see it"
yn

# Final sanity check
tput setaf 6
echo "We are going to transfer all studies owned by $1 to ownership by $2. Is this right? And these are definitely their email addresses?"
yn

tput setaf 9
echo "OK, we're going to do it"

JOB_ID=$(date +%s)

# Copy the default SQL
NEW_FILE=.tmp.change_owner.${JOB_ID}.sql
cp .change_owner.sql $NEW_FILE

# Change the user emails
sed -i "s/current_owner@genestack.com/${1}/" $NEW_FILE
sed -i "s/tester_user@genestack.com/${1}/" $NEW_FILE

# Sort Out Logging Area
AUDIT_DIR=~/.audit.gs_owner
mkdir -p $AUDIT_DIR

# Run the Command
docker exec -i genestack_db_1 bash -c 'mysql -D genestack --password=${MYSQL_ROOT_PASSWORD}' < $NEW_FILE > $AUDIT_DIR/output.${JOB_ID}

rm $NEW_FILE

# Log the Emails Used
echo "OLD_OWNER=$1" >> $AUDIT_DIR/log.${JOB_ID}
echo "NEW_OWNER=$2" >> $AUDIT_DIR/log.${JOB_ID}

# Done - do we restart the container?
tput setaf 2
echo "Done"
echo "Logged to: ${AUDIT_DIR}/log.${JOB_ID} and ${AUDIT_DIR}/output.${JOB_ID}"

tput setaf 9
echo "Do you want to restart the backend container to clear the cache?"
yn

# Restart It
docker restart genestack_backend_1

tput setaf 2
echo "Done"