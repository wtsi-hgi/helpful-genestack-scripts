#!/usr/bin/env bash

# Rollback Changes from the Change Owner Script
# Requires the logged output

# Author: Michael Grace <mg38@sanger.ac.uk>

if [ $# -ne 1 ]; then
	echo "usage: rollback-owner-change.sh TIMESTAMP" >&2
	exit 1
fi

TIMESTAMP=$1

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

AUDIT_DIR=~/.audit.gs_owner

if [[ ! -f $AUDIT_DIR/log.${TIMESTAMP} || ! -f $AUDIT_DIR/output.$TIMESTAMP ]]; then
	tput setaf 1
	echo "Log files for $TIMESTAMP not found" >&2
	tput setaf 9
	exit 1
fi

source $AUDIT_DIR/log.$TIMESTAMP
IDS=$(tail -1 $AUDIT_DIR/output.$TIMESTAMP | cut -d ':' -f 2 | cut -d ' ' -f 2)

echo "We are going to transfer ownership back to $OLD_OWNER. Is this right? The ID numbers in use are: $IDS"
yn

echo "OK, let's revert it"

JOB_ID=$(date +%s)

NEW_FILE=.tmp.revert_owner.${JOB_ID}.sql
cp .revert_owner.sql $NEW_FILE

# Change the Email and ID Numbers
sed -i "s/email_of_new_owner@genestack.com/$OLD_OWNER/" $NEW_FILE
sed -i "s/+++STUDY IDS+++/$IDS/" $NEW_FILE

# Run the Command
docker exec -i genestack_db_1 bash -c 'mysql -D genestack --password=${MYSQL_ROOT_PASSWORD}' < $NEW_FILE 

rm $NEW_FILE

# Log the Revertion
echo REVERTED >> $AUDIT_DIR/revert.$TIMESTAMP.$JOB_ID
echo Changed $NEW_OWNER back to $OLD_OWNER >> $AUDIT_DIR/revert.$TIMESTAMP.$JOB_ID
echo IDs Affected: $IDS >> $AUDIT_DIR/revert.$TIMESTAMP.$JOB_ID

# Done - do we restart the container?
tput setaf 2
echo "Done"
echo "Logged to: $AUDIT_DIR/revert.$TIMESTAMP.$JOB_ID"

tput setaf 9
echo "Do you want to restart the backend container to clear the cache?"
yn

# Restart It
docker restart genestack_backend_1

tput setaf 2
echo "Done"
tput setaf 9

