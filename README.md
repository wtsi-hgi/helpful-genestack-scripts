# Helpful Genestack Scripts for HGI

## `gs-delete`

This script will allow you to delete studies from Genestack and their data in their S3 buckets.

**Usage:**
```
gs-delete {genestack|genestack-qc} TOKEN study_accession ...
```

You can specify either the `genestack` production server or the `genestack-qc` server. You'll need an API token with permission to delete those studies, and then you can provide multiple study accessions, such as `GSF12345678`.

**Location:**
This is in `mercury`'s `$PATH`, so can just be run using `gs-delete`. It is recommended that it is run from `mercury`'s `$HOME` however, becuase the logging file (`.gs-delete.log`) is relative to the location it is run from.

It's located in `~/genestack`.

---

## `gs-upload`

This script will upload data into S3, which will allow you to reference the files in the Genestack Uploader app.

**Usage:**
```
gs-upload [-qc] PROJET_NAME FILE ...
```

By default, will upload to the main Genestack bucket for use on the main Genestack isntance, although the `-qc` flag can be used to upload it to the qc bucket for that instance.

The project name is purely for organisation within the bucket. You can specify multiple files, and glob patterns are allowed.

**Location:**
This is in `mercury`'s `$PATH`, so can be just run using `gs-upload`. It is located in `~/genestack`.

*There's a full description on the Confluence page for the Genestack Uploader app.*

---

## `change-owner.sh`

This script allows you to change the owner of studies in Genestack.

**Usage:**
```
./change-owner.sh CURRENT_OWNER_EMAIL NEW_OWNER_EMAIL
```

**Note:** This will transfer **all** studies owned by `CURRENT_OWNER_EMAIL` to be owned by `NEW_OWNER_EMAIL`

**Note:** This is based off e-mail addresses. It executes the SQL script `.change_owner.sql` which was provided to us by Genestack.

**Warning:** Before transfer, the study **must** be shared with the user it is being transferred to, otherwise they won't be able to see it.

**Location:** This script must be run on the instance running the Genestack containers for the instance you're updating. This is because it has to execute in the database container, and restart the backend continaer (to clear the cache).

**Logging:** This script logs to `~/.audit.gs_owner`, logging the transfer that happened, and the output from the SQL. This output can be used to reverse the change if neccesary.

---

## `rollback-owner-change.sh`

This script will allow to rollback a change made by `change-owner.sh`.

**Usage:**
```
./rollback-owner-change.sh TIMESTAMP
```
where TIMESTAMP is the timestamp tagged onto the files logged by the original script in the auditing directory.

**Note:** This needs to find the logged files from that run, so make sure they exist.

**Location:** This script must be run on the instance running the Genestack containers for the instance you're updating. This is because it has to execute in the database container, and restart the backend container (to clear the cache).

**Logging:** This script logs to `~/.audit.gs_owner`, logging the revertion that happened.
