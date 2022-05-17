### How to delete a template
This article describes how to delete templates in Genestack software using the python script attached below.
  
Requirements
```
Python 3
pip
Genestack python client installed and setup with a user account/token. See How to setup the Genestack python client
```
  
The delete_template_without_limitations.py script and its dependencies:
There is also a repository with these helper scripts (including this script and dependencies) which may be checked out if you have access: https://
github.com/genestack/auxillary-scripts/blob/master/delete_template_without_limitations.py

#### Instructions
Download the delete_template_without_limitations.zip and extract it (see Requirements).
  
Before a template deletion all the studies which have this template set should be manually changed: another template which is not going
to be deleted should be applied (for example, Default template). Apply template manually via the UI.
Run delete template script and follow its login instructions, replacing the host name with the name of the instance the script will apply to.
The script will print “Success” or an error stacktrace in case of an error.
  
```
$ python delete_template_without_limitations.py --
template_accession GSF244345 -H HOSTNAME
```
  
#### Warning:
Currently the Default template CAN be deleted, which may cause issues, so please be careful.
Only users with the “Manage organization” permission can delete templates.
The script doesn’t check that the file with the provided accession actually exists so if nothing is deleted but the script runs
correctly it will still output 'Success'.
The script doesn’t check the type of the file so if a study’s accession is provided instead of a template’s accession the study will
be deleted. However, for deletion of studies please use the script from How to delete a study
