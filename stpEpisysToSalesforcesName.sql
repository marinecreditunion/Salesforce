USE [MCU_SalesForce]
GO
/****** Object:  StoredProcedure [dbo].[stpEpisysToSalesforcesName]    Script Date: 9/30/2020 10:55:12 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- exec stpEpisysToSalesforcesName 495760
ALTER PROCEDURE [dbo].[stpEpisysToSalesforcesName] 

	@iLastKey		bigint

AS
/**************************************************************************************************************************************
REVISION HISTORY:

9/23/2020 HD - Initial Revision  (Updates only)
9/28/2020 HD - Added @iLastKey
9/30


***************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @CurrentDate AS DATE= CAST(GETDATE() AS DATE)

SELECT Deceased_Date__pc,
		PersonMobilePhone,
		PersonHomePhone,
		Work_Phone__pc,
		PersonEmail,
		PersonBirthdate,
		PersonMailingCity,
		FinServ__CurrentEmployer__pc,
		FirstName,
		LastName,
		Address_Verify_Date__c,
		MiddleName,
		FinServ__MotherMaidenName__pc,
		PersonMailingState,
		PersonMailingStreet,
		FinServ__MaritalStatus__pc,
		PersonMailingPostalCode,
		Home_Owner__c,
		Home_Owner_Check_Date__pc,
		Unique_ID__c,
		Odskey

FROM (

SELECT  CAST(n.DEATHDATE AS DATE) as 'Deceased_Date__pc',
		n.MOBILEPHONE as 'PersonMobilePhone',
		n.HOMEPHONE as 'PersonHomePhone',
		n.WORKPHONE as 'Work_Phone__pc',
		n.EMAIL as 'PersonEmail',
		CAST(n.BIRTHDATE AS DATE) as 'PersonBirthdate',
		n.CITY as 'PersonMailingCity',
		n.EMPLOYERNAME as 'FinServ__CurrentEmployer__pc',
		n.FIRST as 'FirstName',
		n.LAST as 'LastName',
		CAST(n.LASTADDRVERIFDATE AS DATE) as 'Address_Verify_Date__c',
		n.MIDDLE as 'MiddleName',
		n.MOTHERSMAIDENNAME as 'FinServ__MotherMaidenName__pc',
		n.STATE as 'PersonMailingState',
		LTRIM(RTRIM(ISNULL(n.STREET,'') + ' ' + ISNULL(n.EXTRAADDRESS,''))) AS 'PersonMailingStreet',
		CASE WHEN n.USERCHAR4='MARRIED' THEN 'MARRIED' ELSE 'NOT MARRIED' END AS 'FinServ__MaritalStatus__pc',
		n.ZIPCODE as 'PersonMailingPostalCode',
		CASE WHEN n.USERCHAR1='OWN' THEN 1 ELSE 0 END AS 'Home_Owner__c',
		CASE WHEN n.USERCHAR1='OWN' THEN CAST(a.OPENDATE AS DATE) ELSE NULL END AS 'Home_Owner_Check_Date__pc',
		CASE WHEN ac.AccountTypeCategory1 IN ('Estate and Trust','Business','Organization') then n.SSN + '-' + ac.AccountTypeCategory1 + '-' + n.ACCOUNT_NUMBER
		                                                                                   else n.SSN + '-Individual-1' end as Unique_ID__c,
		n.Odskey,
		RN=Row_Number() over (Partition by CASE WHEN ac.AccountTypeCategory1 IN ('Estate and Trust','Business','Organization') then n.SSN + '-' + ac.AccountTypeCategory1 + '-' + n.ACCOUNT_NUMBER
		                                                                                   else n.SSN + '-Individual-1' end  order by odsKey desc)

FROM EDS.EDSDB.dbo.NAME n with (nolock)

		inner join EDS.EDSDB.REPORT.ACCOUNT a with (nolock) on n.ACCOUNT_NUMBER=a.NUMBER

		inner join  ARCUSYM000.arcu.ARCUAccountTypeCategory ac with (nolock) on a.[TYPE]=ac.AccountType

		inner join MCU_SalesForce.dbo.Relationships r with (Nolock) on CASE WHEN ac.AccountTypeCategory1 IN ('Estate and Trust','Business','Organization') then n.SSN + '-' + ac.AccountTypeCategory1 + '-' + n.ACCOUNT_NUMBER
		                                                                                   else n.SSN + '-Individual-1' end =r.UniqueID

WHERE --cast(n.OdsRecordCreationDate as Date)=@CurrentDate  
			n.Odskey>@iLastKey
			and n.Type=0  -- Primary Only
			and n.OdsDeleteFlag=0
			and n.SSN>'0'
			and Last<>'(NEW ACCOUNT)') FULLLIST
WHERE RN=1  -- If multiple showing for same name, only pull most recent.  Don't need to iterate through all
ORDER BY Odskey

END;
