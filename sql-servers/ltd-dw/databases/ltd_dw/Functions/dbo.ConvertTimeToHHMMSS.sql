SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


 CREATE function [dbo].[ConvertTimeToHHMMSS]
(
    @time decimal(28,3), 
    @unit varchar(20)
)

-- usage select dbo.[ConvertTimeToHHMMSS](16560, 'second')
returns varchar(20)
as
begin

    declare @seconds decimal(18,3), @minutes int, @hours int;

    if(@unit = 'hour' or @unit = 'hh' )
        set @seconds = @time * 60 * 60;
    else if(@unit = 'minute' or @unit = 'mi' or @unit = 'n')
        set @seconds = @time * 60;
    else if(@unit = 'second' or @unit = 'ss' or @unit = 's')
        set @seconds = @time;
    else set @seconds = 0; -- unknown time units

    set @hours = convert(int, @seconds /60 / 60);
    set @minutes = convert(int, (@seconds / 60) - (@hours * 60 ));
    set @seconds = @seconds % 60;

    return 
        convert(varchar(9), convert(int, @hours)) + ':' +
        right('00' + convert(varchar(2), convert(int, @minutes)), 2) + ':' +
        right('00' + convert(varchar(6), @seconds), 6)

end
GO
