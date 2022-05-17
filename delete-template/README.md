### How to delete a template
This article describes how to delete templates in Genestack software using the python script attached below.
  
Requirements
```
Python 3
pip
Genestack python client installed and setup with a user account/token. 
See How to setup the Genestack python client
  github repo: https://github.com/genestack/python-client
  documentation: https://genestack-client.readthedocs.io/en/stable/
```

#### Instructions
  
Before a template deletion all the studies which have this template set should be manually changed: another template which is not going
to be deleted should be applied (for example, Default template). Apply template manually via the UI.
Run delete template script and follow its login instructions, replacing the host name with the name of the instance the script will apply to.
The script will print “Success” or an error stacktrace in case of an error.
  
```
$ python delete_template_without_limitations.py --template_accession GSF2330543 -H https://genestack.sanger.ac.uk -u root
Fail to load password for alias "root": No recommended backend was available. Install a recommended 3rd party backend package; or, install the keyrings.alt package if you want to use the non-recommended backends. See https://pypi.org/project/keyring for details.
   1) by token
   2) by email and password
   3) anonymously
How do you want to login: 1
Connecting to https://genestack.sanger.ac.uk
token: 
Success

```
  
#### Warning:
Currently the Default template CAN be deleted, which may cause issues, so please be careful.
Only users with the “Manage organization” permission can delete templates.
The script doesn’t check that the file with the provided accession actually exists so if nothing is deleted but the script runs
correctly it will still output 'Success'.
The script doesn’t check the type of the file so if a study’s accession is provided instead of a template’s accession the study will
be deleted. However, for deletion of studies please use the script from How to delete a study
