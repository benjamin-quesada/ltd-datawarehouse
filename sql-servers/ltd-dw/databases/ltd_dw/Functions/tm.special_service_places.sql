SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [tm].[special_service_places] (@lat INT, @long INT) RETURNS VARCHAR(50) AS

BEGIN
   declare @place as varchar(50)
   
   set @place = ''
   if @lat is null or @long is null
      set @place = 'zee no coordinates'

   if @lat = 0 or @long = 0
      set @place = 'zee no coordinates'

   if @lat <= 440990001 and @lat >= 440910001 and @long >= -1231284883 and @long <= -1231264883 set @place = @place + 'River Road Station'
   if @lat <= 440740001 and @lat >= 440715001 and @long >= -1230450001 and @long <= -1230432001 set @place = @place + 'Gateway Station'
   if @lat <= 440594801 and @lat >= 440552801 and @long >= -1230800001 and @long <= -1230625001 set @place = @place + 'Autzen'
--   if @lat <= 440570000 and @lat >= 440540000 and @long >= -1230800001 and @long <= -1230625001 set @place = @place + 'Autzen Stadium Spectator' --overlap with Autzen
--   if @lat <= 440839001 and @lat >= 440819101 and @long >= -1230464001 and @long <= -1230412001 set @place = @place + 'Clarion'
   if @lat <= 440445578 and @lat >= 440414574 and @long >= -1230433338 and @long <= -1230377007 set @place = @place + 'Garage'
   if @lat <= 440848001 and @lat >= 440084101 and @long >= -1231768901 and @long <= -1231751001 set @place = @place + 'Shasta'
   if @lat <= 441025001 and @lat >= 441002001 and @long >= -1230579001 and @long <= -1230557501 set @place = @place + 'C. Fellowship'
   if @lat <= 440573001 and @lat >= 440550001 and @long >= -1230231001 and @long <= -1230197001 set @place = @place + 'Centennial Shuttle'
   if @lat <= 440620001 and @lat >= 440600001 and @long >= -1230720001 and @long <= -1230650001 set @place = @place + 'Centennial Shuttle Autzen'
--   if @lat <= 440382001 and @lat >= 440370001 and @long >= -1230920001 and @long <= -1230870001 set @place = @place + 'Civic'
   if @lat <= 440495001 and @lat >= 440467201 and @long >= -1229270001 and @long <= -1229260001 set @place = @place + 'Thurston High'
   if @lat <= 440450001 and @lat >= 440440001 and @long >= -1229600001 and @long <= -1229000001 set @place = @place + 'Thurston Station'
   if @lat <= 440480001 and @lat >= 440416001 and @long >= -1230800001 and @long <= -1230770001 set @place = @place + 'UO Station'
   if @lat <= 440555000 and @lat >= 440510000 and @long >= -1230937000 and @long <= -1230916000 set @place = @place + 'Hilton Hotel'
   if @lat <= 440460001 and @lat >= 440447501 and @long >= -1230235001 and @long <= -1230198001 set @place = @place + 'Springfield Station'
   if @lat <= 440454001 and @lat >= 440429001 and @long >= -1230198002 and @long <= -1230186001 set @place = @place + 'Booth Kelly Parking'
   if @lat <= 440532601 and @lat >= 440520201 and @long >= -1230126801 and @long <= -1230088001 set @place = @place + 'Springfield Middle School'
   if @lat <= 440340000 and @lat >= 440330000 and @long >= -1230880000 and @long <= -1230870000 set @place = @place + 'SEHS Practice Field'
   IF @lat <= 440156501 AND @lat >= 440060001 AND @long >= -1230470001 AND @long <= -1230274001 SET @place = @place + 'LCC'
   IF @lat <= 440668001 AND @lat >= 440655701 AND @long >= -1231032501 AND @long <= -1231025001 SET @place = @place + 'Valley River Inn'
--   if @lat <= 440710001 and @lat >= 440680001 and @long >= -1231158001 and @long <= -1231067291 set @place = @place + 'behind AutoPros (VRC)'
   IF @lat <= 440698400 AND @lat >= 440684500 AND @long >= -1231108300 AND @long <= -1231086700 SET @place = @place + 'VRC 2010 FB'
   IF @lat <= 440670001 AND @lat >= 440660001 AND @long >= -1231120001 AND @long <= -1231041001 SET @place = @place + 'VRC Station'
   IF @lat <= 440569001 AND @lat >= 440540001 AND @long >= -1230820001 AND @long <= -1230790001 SET @place = @place + 'Alton Baker Park.'
   IF @lat <= 440461001 AND @lat >= 440420001 AND @long >= -1231100001 AND @long <= -1231015001 SET @place = @place + 'Fairgrounds'
   IF @lat <= 440128001 AND @lat >= 440100000 AND @long >= -1230890001 AND @long <= -1230860001 SET @place = @place + '40th and Donald'
   IF @lat <= 440548001 AND @lat >= 440539001 AND @long >= -1230918001 AND @long <= -1230886001 SET @place = @place + '5th and Pearl'
   IF @lat <= 440560000 AND @lat >= 440540001 AND @long >= -1230888000 AND @long <= -1230860000 SET @place = @place + '4th and High'
   IF @lat <= 440485001 AND @lat >= 440448001 AND @long >= -1230270001 AND @long <= -1230251001 SET @place = @place + 'Island Park'
   IF @lat <= 440620001 AND @lat >= 440490001 AND @long >= -1233900001 AND @long <= -1233600001 SET @place = @place + 'Country Fair'
   IF @lat <= 442184901 AND @lat >= 442167001 AND @long >= -1232050001 AND @long <= -1232010001 SET @place = @place + 'Scandinavian Festival'
   IF @lat <= 440495001 AND @lat >= 440460001 AND @long >= -1230945001 AND @long <= -1230920000 SET @place = @place + 'Eugene Station'
   IF @lat <= 440870001 AND @lat >= 440850001 AND @long >= -1230397001 AND @long <= -1230325000 SET @place = @place + 'Symantec'
   IF @lat <= 440840000 AND @lat >= 440800000 AND @long >= -1230420001 AND @long <= -1230390000 SET @place = @place + 'Hutten & Kruse'
--   if @lat <= 440270001 and @lat >= 440250001 and @long >= -1230870001 and @long <= -1230830001 set @place = @place + 'Amazon Station'
--   if @lat <= 440437248 and @lat >= 440406517 and @long >= -1230752258 and @long <= -1230740259 set @place = @place + 'Mac Court'
--   if @lat <= 440447248 and @lat >= 440400517 and @long >= -1230700000 and @long <= -1230680000 set @place = @place + 'Hayward Field 15th & Agate'
--   if @lat <= 440475000 and @lat >= 440461200 and @long >= -1230720000 and @long <= -1230680000 set @place = @place + 'Franklin and Agate'
--   if @lat <= 440572801 and @lat >= 440557301 and @long >= -1230230001 and @long <= -1230198001 set @place = @place + 'Hamlin Middle School'
   IF @lat <= 440442000 AND @lat >= 440425000 AND @long >= -1230710000 AND @long <= -1230680000 SET @place = @place + 'Hayward Autzen Spectator'
   IF @lat <= 440414500 AND @lat >= 440413000 AND @long >= -1230755000 AND @long <= -1230740000 SET @place = @place + 'Hayward Media'
   IF @lat <= 440418310 AND @lat >= 440414100 AND @long >= -1230755000 AND @long <= -1230740000 SET @place = @place + 'Hayward VIP'
   IF @lat <= 440450000 AND @lat >= 440440000 AND @long >= -1230640001 AND @long <= -1230625001 SET @place = @place + 'Athletes Market of Choice (Walnut)'
--   if @lat <= 440650000 and @lat >= 440640000 and @long >= -1230800001 and @long <= -1230700000 set @place = @place + 'Red Lion Airport'
--   if @lat <= 440880000 and @lat >= 440870000 and @long >= -1230440000 and @long <= -1230420000 set @place = @place + 'Motel 6 Airport'
--   if @lat <= 440868000 and @lat >= 440862000 and @long >= -1230440000 and @long <= -1230420000 set @place = @place + 'Quality Inn Airport'
--   if @lat <= 441210000 and @lat >= 441200000 and @long >= -1232200000 and @long <= -1232100000 set @place = @place + 'Airport Hilton/Gateway'
--   if @lat <= 441195000 and @lat >= 441190000 and @long >= -1232200000 and @long <= -1232100000 set @place = @place + 'Airport UO Dorms'
--   if @lat <= 440668001 and @lat >= 440650000 and @long >= -1231032501 and @long <= -1231025001 set @place = @place + 'Valley River Inn VIP'
   IF @lat <= 440388000 AND @lat >= 440382000 AND @long >= -1230840000 AND @long <= -1230800000 SET @place = @place + 'SEHS Spectator 19th & Patterson'
   IF @lat <= 440410000 AND @lat >= 440395000 AND @long >= -1230709999 AND @long <= -1230690000 SET @place = @place + 'Hayward Gateway'
   IF @lat <= 440410000 AND @lat >= 440395000 AND @long >= -1230713800 AND @long <= -1230710000 SET @place = @place + 'Hayward Hilton'
--   if @lat <= 440432100 and @lat >= 440425500 and @long >= -1230748000 and @long <= -1230745000 set @place = @place + 'Hayward SEHS Spectator'
   IF @lat <= 440492500 AND @lat >= 440490000 AND @long >= -1230810000 AND @long <= -1230801000 SET @place = @place + 'Phoenix Inn Airport'
--   if @lat <= 440455000 and @lat >= 440440000 and @long >= -1230630000 and @long <= -1230610000 set @place = @place + 'Holiday Inn Express (Walnut) Airport'
--   if @lat <= 440459000 and @lat >= 440457000 and @long >= -1230660000 and @long <= -1230656000 set @place = @place + 'Days Inn Airport'
--   if @lat <= 440463000 and @lat >= 440461000 and @long >= -1230676000 and @long <= -1230670000 set @place = @place + 'Best Western Green Tree Airport'
--   if @lat <= 440466000 and @lat >= 440463000 and @long >= -1230690000 and @long <= -1230680000 set @place = @place + 'Best Western New Oregon Airport'
--   if @lat <= 440500000 and @lat >= 440499000 and @long >= -1230820000 and @long <= -1230810000 set @place = @place + '66 Motel Airport'
--   if @lat <= 440535000 and @lat >= 440531000 and @long >= -1231080000 and @long <= -1231050000 set @place = @place + 'Express Inn Airport'
--   if @lat <= 440540000 and @lat >= 440532000 and @long >= -1231120000 and @long <= -1231110000 set @place = @place + 'Econo Lodge Airport (on 6th)'
--   if @lat <= 440525000 and @lat >= 440515000 and @long >= -1231110000 and @long <= -1231100000 set @place = @place + 'Econo Lodge Airport (on 7th)'
   IF @place = '' SET @place = 'zee unknown'
  
   RETURN @place
END
GO
