SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [fin].[ExportEdenFinancialTransactionsToFile_Rafactor]
                     @pathName           varchar(500) = '', 
                    @fileName           varchar(50)  = '', 
                    @addTStoFileName    varchar(50) = 'X',
                    @minPostNo          integer      = 0,
                    @sourceModule       char(2)      = 'XX', 
                    @expControlPattern  varchar(50)  = 'XX', 
                    @revControlPattern  varchar(50)  = 'XX',
                    @useAcctXrefPos     char(1)      = 'X', 
                    @isRecreate         char(1)      = 'X', 
                    @recreateSetID      integer      =  0
/*

 EXEC [fin].[ExportEdenFinancialTransactionsToFile_Rafactor]
    @pathName           = 'E:\filedrop\finance_internal', 
                    @fileName           = 'CRTransactions.txt',
                    @addTStoFileName    = 'Y',
                    @minPostNo          = 57000,
                    @sourceModule       = 'CR', 
                    @expControlPattern  = '.000.00.39500', 
                    @revControlPattern  = '.000.00.39400', 
                    @useAcctXrefPos     = 'Y', 
                    @isRecreate         = 'N', 
                    @recreateSetID      =  0
*/


AS 

/*
Procedure to extract Eden financial transactions by specific module and write them to 
a text file in Munis import format (Standard Account Format -- multiple journals).
This procedure will be scheduled via the SQL Server agent to run on a regular basis (i.e. weekly)
and the Munis scheduler will be used to automatically pick up the file and import it

Parameters:
@pathname -- network path (UNC or mapped drive visible to SQL Server/Agent)
    * e.g. L:\MyPath\Exports\Module, or \\myFileServer\MyShare\Exports\Module
      must have permissions set to allow SQL Server/Agent service account to read/write to it
@fileName -- name of the file to export to 
@addTStoFileName -- will append date/time stamp to filename if 'Y'; any other value is assummed 'N'
@minPostNo -- set to the highest post_no in Eden esxtranr prior to the cut-over to Munis
    * could be gotten from the "go-live" conversion transaction set
    * this is to ensure we don't import previously converted transactions
@sourceModule -- the Eden module to extract transactions for (e.g. PY, LI, UB, PM, etc.)
@expControlPattern -- the GL account structure that represents expenditure control
    * fund will be tacked on, so must have delimiter at the beginning of the pattern
    * summary (or orignating?!?) transactions for this account will be filtered out of the result set
@revControlPattern -- the GL account structure that represents revenue control; see above
@useAcctXrefPos -- Y/N flag indicating the position of the file to place the GL account
    * Y = Use the Account cross reference position in the file layout
    * N = Use the Munis Long Account position in the file layout
@isRecreate -- Y/N flag indicating if procedure should recreate previous export file
    * Y = recreate a previous export file
    * N = create file with ONLY previously unexported transactions for source module
@recreateSetID -- ID of the log record that defines the 'set' of transactions to recreate
    * only applicable if @isRecreate = 'Y'

------------------LTD_GLOSSARY---------------
UPDATED BY:	Sopheap Suy
UPDATED DT:  10/31/2024
purpose	 :  Add object activities on who, what, when call this object
			write this data to aud.object_activity table everytime it's called */

SET NOCOUNT ON

DECLARE @SPROC VARCHAR(100)
SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

INSERT INTO DBA.[aud].[Object_Activity]
	([server_name], [database_name] ,[host_name], [System_User], [object_name]
	,[client_net_address], [local_net_address], [auth_Scheme], [last_read], [last_write]
	,[most_recent_sql_handle], [Timestamp], object_type)
SELECT DISTINCT @@SERVERNAME, DB_NAME(),HOST_NAME(),SYSTEM_USER, @SPROC,
	client_net_address, local_net_address , auth_Scheme, last_read, last_write 
	,most_recent_sql_handle, CURRENT_TIMESTAMP AS [Timestamp], 'PROC'
FROM sys.dm_exec_connections 
WHERE session_id = @@SPID ;


declare       @retStatus  integer = 0;
declare       @loPostNo   integer = 0;
declare       @hiPostNo   integer = 0;
declare       @errMessage varchar(80);
declare       @bigStr     varchar(max) = '';
declare       @crlf       char(2); 

set @crlf = char(13) + char(10); 

-- create the log table if it doesn't already exist 
if object_id(N'wrk.ExportEdenFinancialLog',N'U') is NULL
  begin
   create table wrk.ExportEdenFinancialLog
      (ID             integer identity(1,1) NOT NULL PRIMARY KEY CLUSTERED, 
       runDateTime    datetime not null default getdate(), 
       runUser        varchar(40) not null default system_user, 
       sourceModule   char(2) not null, 
       loPostNo       integer not null, 
       hiPostNo       integer not null, 
       errorStatus    char(1) not null,
       errorText      varchar(80) null
      );
   create index i1_ModuleDateTime on wrk.ExportEdenFinancialLog
      (sourceModule, errorStatus, runDateTime desc) include (loPostNo, hiPostNo); 
  end;

-- validate the sanity of all the paramaters
if IsNull(@pathName,'') = '' or IsNull(@fileName,'') = ''
   begin 
     set @errMessage = 'Blank or NULL (path or file) supplied to procedure';
     set @retStatus = -1; 
   end; 

if isNull(@sourceModule,'XX') = 'XX'
   begin 
     set @errMessage = 'Blank or NULL sourceModule supplied to procedure';
     set @retStatus = -1; 
   end;  

if IsNull(@expControlPattern,'XX') = 'XX' or IsNull(@revControlPattern,'XX') = 'XX'
   begin 
     set @errMessage = 'Blank or NULL exp/rev control pattern supplied to procedure';
     set @retStatus = -1; 
   end; 

if Isnull(@useAcctXrefPos,'X') not like '[YN]'
   begin 
     set @errMessage = 'UseAcctXrefPos <> Y/N';
     set @retStatus = -1; 
   end; 

if Isnull(@addTStoFileName,'X') not like '[YN]'
   begin 
     set @errMessage = 'addTStoFileName <> Y/N';
     set @retStatus = -1; 
   end; 

if isNull(@sourceModule,'XX') = 'XX'
   begin 
     set @errMessage = 'Blank or NULL sourceModule supplied to procedure';
     set @retStatus = -1; 
   end; 

if IsNull(@minPostNo,0) = 0
   begin 
     set @errMessage = 'Absolute minPostNo must be > 0';
     set @retStatus = -1; 
   end; 

if @retStatus <> 0 
  begin
      -- raiserror with a value of 16 will set the job status to Failed if run via job
      set @errMessage = 'Invalid parameters: ' + @errMessage;
      insert into wrk.ExportEdenFinancialLog (sourceModule, loPostNo, hiPostNo, errorStatus, errorText)
      values (@sourceModule, @loPostNo, @hiPostNo, 'E', @errMessage);  
      RAISERROR(@errMessage, 16, 1); 
      return @retStatus; 
  end;

-- support procedure to write the file doesn't like path to have a trailing '\' so strip it off
if right(rtrim(@pathName),1) = '\' 
  set @pathName = left(@pathname,len(@pathName)-1); 

-- Tack on date/time to the end of the filename if requested; append before the file extension (first ".")
if @addTStoFileName = 'Y'
  set @fileName = 
         case when charindex('.',@fileName,1) <> 0 then left(@fileName,charindex('.',@fileName,1)-1)
              else @fileName
         end + 
         '_' + replace(replace(convert(varchar(30),getdate(),120),' ','_'),':','-') + 'hms' +
         case when charindex('.',@fileName,1) <> 0 then substring(@fileName,charindex('.',@fileName,1),50)
              else ''
         end;        

-- Set the post_no range to look at:
-- loPostNo is either the minimum passed into the procedure (the highest post no 
--    that was processed in Eden before going live with Munis), or the next 
--    available one from the most recent export run for this module, 
--    or when recreating a batch, what was processed in that batch
-- hiPostNo was what was originally used to create the batch if doing a recreate, 
--    or the top of the integer range
EXEC sp_configure 'show advanced options', 1;    
RECONFIGURE;    
EXEC sp_configure 'Ole Automation Procedures', 1;    
RECONFIGURE;    

set @loPostNo = -1; 
set @hiPostNo = -1; 

if @isRecreate = 'Y'
  begin
    -- we need to grab the post no range that was actually processed for that particular
    -- batch, based on the ID supplied to the procedure.  If we can't find that row, 
    -- then that is an error and we bail early
    select @loPostNo = loPostNo, @hiPostNo = hiPostNo
    from wrk.ExportEdenFinancialLog
    where ID = @recreateSetID and errorStatus = 'S' -- only recreate where original run was a success; 
    if @loPostNo = -1 or @loPostNo is NULL
       or @loPostNo = -1 or @loPostNo is NULL 
      begin
         set @errMessage = 'Recreate ID not associated with successful export, or not found';
         insert into wrk.ExportEdenFinancialLog (sourceModule, loPostNo, hiPostNo, errorStatus, errorText)
         values (@sourceModule, 0, 0, 'E', @errMessage);  
         RAISERROR(@errMessage, 16, 1);  
         return -1
      end; 
  end
  else
    begin
      -- get the highest post no processed in the most recent run
      -- for the same module, where it was a successful process
      select top 1 @loPostNo = hiPostNo + 1 
      from wrk.ExportEdenFinancialLog
      where sourceModule = @sourceModule and errorStatus = 'S'
      order by runDateTime desc;  
      -- if we can't find it, use the baseline (minimum) plus 1
      if @loPostNo = -1 or @loPostNo is null 
        set @loPostNo = @minPostNo + 1; 
      set @hiPostNo = 2147483647
    end; 

-- this will pull all the affected rows into a #tmp table
-- using the sourceModule, and postNo ranges as a filter
-- it also will eliminate any transactions that are posting to exp/rev control accounts
select r.ORIG_JOURNAL, r.TRAN_DOC_NO, r.POST_NO, r.DOC_DATE, r.DOC_DESC, r.SUMMARY_DOC,
       d.TRAN_TYPE, d.DESCRIPTION, d.DOC_YEAR, d.ACCT_PERIOD, 
       d.LINE_NO, d.SUB_LINE_NO, 
       debit_credit = case when d.AMOUNT < 0 then
                              case when d.DEBIT_CREDIT = 'D' then 'C'
                                   else 'D'
                              end
                           else d.DEBIT_CREDIT
                      end,
       tranAmt = case when d.AMOUNT < 0 then d.AMOUNT * -1
                      else d.AMOUNT
                 end,
       a.ACCT_TYPE, a.ACCT_ID, LTRIM(RTRIM(a.LEVEL_1)) as fund, a.ACCT_NO, a.ACCT_TITLE,
       p.TRANSACTION_ID, p.STRING_TYPE, p.STRING_ID, s.PA_STRING_NO,
       projAmt = case when p.TRAN_AMOUNT < 0 then p.TRAN_AMOUNT * -1
                      else p.TRAN_AMOUNT
                 end, 
       rowNum = row_number() 
                over (partition by r.post_no, r.DOC_DATE 
                      order by r.post_no, r.DOC_DATE, d.tran_doc_no, d.line_no, d.sub_line_no, p.transaction_id)
into #tmp
from [LTD-FINANCE].GoldStandard.dbo.esxtranr r 
INNER join [LTD-FINANCE].GoldStandard.dbo.esgtrand d 
       on r.TRAN_DOC_NO = d.TRAN_DOC_NO
     inner join [LTD-FINANCE].GoldStandard.dbo.ESXACCTR a
       on d.ACCT_ID = a.ACCT_ID
          and d.DOC_YEAR = a.ACCT_YEAR
     left outer join [LTD-FINANCE].GoldStandard.dbo.ESCPTRND p
       on p.TRAN_DOC_NO = d.TRAN_DOC_NO
          and p.TRAN_LINE_NO = d.LINE_NO
          and p.TRAN_SUB_LINE_NO = d.SUB_LINE_NO
     left outer join [LTD-FINANCE].GoldStandard.dbo.PAStringNoStatusCheck s
       on s.STRING_TYPE = p.STRING_TYPE
          and s.STRING_ID = p.STRING_ID
where r.ORIG_JOURNAL = @sourceModule 
      and r.POST_NO >= @loPostNo
      and r.POST_NO <= @hiPostNo
      and not (d.ACCT_TYPE = 'B' and (LTRIM(RTRIM(a.ACCT_NO)) like LTRIM(RTRIM(a.LEVEL_1)) + '%' + @expControlPattern
                                      or LTRIM(RTRIM(a.ACCT_NO)) like LTRIM(RTRIM(a.LEVEL_1)) + '%' + @revControlPattern)
              ); 

-- create an index to speed up the following update statement
create index i1_tmp on #tmp (tran_doc_no, line_no, sub_line_no) include (projAmt); 

-- this deducts all of the project detail amounts from the GL transaction amount, as
-- the project rows will be written in detail, and we'll write one more row for the 
-- balance of the transaction that wasn't associated with a project string
update #tmp 
   set tranAmt = tranAmt - pt.totalProjAmt
from #tmp inner join 
            (select tran_doc_no, line_no, sub_line_no, sum(isnull(projAmt,0)) totalProjAmt
             from #tmp t1
             group by tran_doc_no, line_no, sub_line_no) as pt
       on #tmp.TRAN_DOC_NO = pt.TRAN_DOC_NO
          and #tmp.LINE_NO = pt.LINE_NO 
          and #tmp.SUB_LINE_NO = pt.SUB_LINE_NO; 

-- grab the post_no ranges that were included in this run so that we can log them later
select @loPostNo = isNull(min(POST_NO),0), @hiPostNo = isNull(max(POST_NO),0)
from #tmp; 

-- this will build the string
select @bigStr = @bigStr +
       case
         when source = 1 then 
            'H' + upper(ORIG_JOURNAL) + space(4) + 
            upper(ORIG_JOURNAL) + cast(POST_NO as varchar(12)) + 
            space(12 - len(upper(ORIG_JOURNAL) + cast(POST_NO as varchar(12)))) +
            cast(DOC_YEAR as varchar(4)) +
            case when ACCT_PERIOD < 10 then '0' + cast(ACCT_PERIOD as char(1)) 
                 else cast(ACCT_PERIOD as varchar(2))
            end +
            replace(convert(varchar(10),DOC_DATE,101),'/','')
         else 
            'D' + space(19) + 
            case when @useAcctXrefPos = 'Y' then rtrim(ACCT_NO) + space(35 - len(rtrim(ACCT_NO)))
                 else space(35)
            end +
            rtrim(IsNull(DESCRIPTION,'')) + space(30 - len(rtrim(IsNull(DESCRIPTION,'')))) +
            upper(TRAN_TYPE) + cast(TRAN_DOC_NO as varchar(12)) + replace(convert(varchar(10),DOC_DATE,101),'/','') 
			+space(4)+ ISNULL(debit_credit,'') + 
            cast(cast(IsNull(Amt,0)  * 100.00 as bigint) as varchar(13)) + space(13 - len(cast(cast(IsNull(Amt,0) * 100.00 as bigint) as varchar(13)))) +
            space(1) + '0000000000000' + space(5) + 'A' + 
            ACCT_TYPE + case when @useAcctXrefPos = 'N' then rtrim(ACCT_NO) + space(55 - len(rtrim(ACCT_NO)))
                             else space(55)
                        end +
            STRING_TYPE + rtrim(IsNull(PA_STRING_NO,'')) + space(42 - len(rtrim(IsNull(PA_STRING_NO,''))))
       end 
       + @crlf
from 
   (
    -- this is a placeholder for the header record, which we will get one per posting number
    -- based on the rowNum column that was set by the row_number() function; 
    -- non of the data elements other than the posting info is used (post_no/date, fiscal period)
    select 1 as source, 'header' as sourceDesc, ORIG_JOURNAL, 0 TRAN_DOC_NO, POST_NO, DOC_DATE, 
           '' as TRAN_TYPE, '' as DESCRIPTION, DOC_YEAR, ACCT_PERIOD, 
           0 as LINE_NO, 0 as SUB_LINE_NO, '' as debit_credit, 0 as Amt,
           '' as ACCT_TYPE, 0 as ACCT_ID, '' as fund, '' as ACCT_NO, 
           '' as STRING_TYPE, '' as PA_STRING_NO 
    from #tmp where rowNum = 1
    union all
    -- this will give us one row for each project detail transaction, using the project transaction amount
    -- in some cases, the project transaction amount is zero (as when distributing a very small benefit 
    -- amount against multiple projects, and rounding takes it to 0.00)
    select 2 as source, 'project' as sourceDesc, ORIG_JOURNAL, TRAN_DOC_NO, POST_NO, DOC_DATE, 
           TRAN_TYPE, DESCRIPTION, DOC_YEAR, ACCT_PERIOD, 
           LINE_NO, SUB_LINE_NO, debit_credit, projAmt as Amt,
           ACCT_TYPE, ACCT_ID, fund, ACCT_NO, 
           '' as STRING_TYPE, '' as PA_STRING_NO
    from #tmp where TRANSACTION_ID is not null and projAmt <> 0.00
    union all
    -- this will give us one more row per transaction line, with the amount being the GL transaction 
    -- amount less any amount applied to projects (based on the update statement above)
    -- in some cases, the GL transaction amount will be 0, as when ALL of the transaction is 
    -- applied against one or more projects; we have to use a distinct here to make sure we only 
    -- get one row per transaction/line/sub-line
    select distinct 3 as source, 'gl' as sourceDesc, ORIG_JOURNAL, TRAN_DOC_NO, POST_NO, DOC_DATE, 
           TRAN_TYPE, DESCRIPTION, DOC_YEAR, ACCT_PERIOD, 
           LINE_NO, SUB_LINE_NO, debit_credit, tranAmt,
           ACCT_TYPE, ACCT_ID, fund, ACCT_NO, ' ' as STRING_TYPE, '' as PA_STRING_NO
    from #tmp where tranAmt <> 0.00
   ) as trans
-- ordering by post_no, doc_date, tran_doc_no, source will make sure my header for the post_no 
-- precedes any of the documents within it (based on how the partition by was used)
order by post_no, DOC_DATE, TRAN_DOC_NO, source, LINE_NO, SUB_LINE_NO; 

-- write that big ol' string out to the file
exec @retStatus = spWriteStringToFile @bigStr, @pathName, @fileName; 

if @retStatus <> 0
  -- some type of error writing to the file
  begin
    set @errMessage = 'Error writing to export file: ' + cast(@retStatus as varchar(20));
    insert into wrk.ExportEdenFinancialLog (sourceModule, loPostNo, hiPostNo, errorStatus, errorText)
    values (@sourceModule, 0, 0, 'E', @errMessage);  
    RAISERROR(@errMessage, 16, 1);  
    return -1; 
  end
else 
if @loPostNo = 0 and @hiPostNo = 0
  -- there were no rows in the temp table (no transactions meeting range)
  -- write a warning to the error log, but consider this successfull (no raiserror)
  insert into wrk.ExportEdenFinancialLog (sourceModule, loPostNo, hiPostNo, errorStatus, errorText)
  values (@sourceModule, 0, 0, 'W', 'No transactions found in post_no range');
else
  -- successful
  insert into wrk.ExportEdenFinancialLog (sourceModule, loPostNo, hiPostNo, errorStatus, errorText)
  values (@sourceModule, @loPostNo, @hiPostNo, 'S', ''); 
 
drop table #tmp;
    
EXEC sp_configure 'Ole Automation Procedures', 0;    
RECONFIGURE; 
EXEC sp_configure 'show advanced options', 0;    
RECONFIGURE;

GO
