-- start of user input
SET @current_owner_email = 'current_owner@genestack.com'; SET @new_owner_email = 'tester_user@genestack.com';
-- end of user input
SET @new_owner_id = ( SELECT userId
FROM Users
WHERE email = @new_owner_email );
SET @study_file_ids = (
SELECT GROUP_CONCAT(Files.fileId) FROM Files
JOIN Users ON Users.userId = Files.ownerId JOIN SimpleMetainfo AS StudyDataType
ON Files.fileId = StudyDataType.objectId AND StudyDataType.metaKey = 'genestack:dataType' AND
StudyDataType.value = 'study' LEFT JOIN SimpleMetainfo AS InitVersion
ON Files.fileId = InitVersion.objectId AND InitVersion.metaKey = 'genestack:version'
JOIN SimpleMetainfo AS Accession
ON Files.fileId = Accession.objectId AND
Accession.metaKey = 'genestack:accession' WHERE Users.email = @current_owner_email
AND InitVersion.objectId IS NULL
);
SELECT CONCAT('List of file ids affected: ', @study_file_ids) AS AffectedStudies;
START TRANSACTION;
UPDATE FilesAceByGroups FABG SET FABG.ownerId = @new_owner_id WHERE FIND_IN_SET(FABG.fileId, @study_file_ids);
UPDATE Files F SET F.ownerId = @new_owner_id WHERE FIND_IN_SET(F. fileId, @study_file_ids);
COMMIT;