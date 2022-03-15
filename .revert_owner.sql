-- start of user input
SET @new_owner_email = 'email_of_new_owner@genestack.com';
-- take the following ids from the output of the script above
SET @study_file_ids = '+++STUDY IDS+++';
-- end of user input
SET @new_owner_id = (
	    SELECT userId
	    FROM Users
	    WHERE email = @new_owner_email
);
START TRANSACTION;
UPDATE FilesAceByGroups FABG SET FABG.ownerId = @new_owner_id 
WHERE FIND_IN_SET(FABG.fileId, @study_file_ids);
UPDATE Files F SET F.ownerId = @new_owner_id WHERE FIND_IN_SET(F.
	fileId, @study_file_ids);
COMMIT;
