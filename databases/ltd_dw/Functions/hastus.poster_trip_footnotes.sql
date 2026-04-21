SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- select * from [hastus].[poster_trip_footnotes]()
CREATE FUNCTION [hastus].[poster_trip_footnotes]()
RETURNS @tbl_fns TABLE(poster_no INT, trip_fn_id VARCHAR(8), trips SMALLINT, rn SMALLINT, fn_char CHAR(1), fn_char_sort TINYINT, fn_text VARCHAR(2000), fn_text_spanish VARCHAR(2000), fn_text_combined VARCHAR(4000))
AS
BEGIN

declare @max_fn_chars_id int = (select max(the_id) from hastus.bsi_footnote_chars) 

INSERT @tbl_fns(poster_no, trip_fn_id, trips)
SELECT p.poster_seq_no
      ,t.note
      ,COUNT(*)
  FROM      hastus.tripstpe       trpstp
 INNER JOIN [ltd-hastus2].TEMPhastus2021TEMP.dbo.trip    t   ON t.trip_no        = trpstp.trip_no
 INNER JOIN [ltd-hastus2].TEMPhastus2021TEMP.dbo.vscver  vsc ON vsc.vscver_id    = trpstp.vscver_id
 INNER JOIN [ltd-hastus2].TEMPhastus2021TEMP.dbo.note    n   ON n.note_id        = t.note
 INNER JOIN [ltd-hastus2].TEMPhastus2021TEMP.dbo.[stop]  s   ON s.stop_id COLLATE SQL_Latin1_General_CP850_CI_AS         = trpstp.stop_id
 INNER JOIN [ltd-hastus2].TEMPhastus2021TEMP.dbo.poster  p   ON p.stop_no        = s.stop_no
 INNER JOIN [ltd-hastus2].TEMPhastus2021TEMP.dbo.postrte pr  ON pr.poster_seq_no = p.poster_seq_no AND pr.route_id = t.route_id
 INNER JOIN (SELECT trip_no, last_stop_position = MAX(stop_position) FROM hastus.tripstpe GROUP BY trip_no) ls ON ls.trip_no = trpstp.trip_no
 WHERE ISNUMERIC(LEFT(LTRIM(t.route_id COLLATE SQL_Latin1_General_CP850_CI_AS ), 1)) = 1
   AND vsc.sched_type_id IN(0,5,6)
   AND t.note IS NOT NULL
   AND n.purpose IN(1,3)
   AND ls.last_stop_position <> trpstp.stop_position                                                                                                                                                   --eliminated last stop of trip
   AND NOT EXISTS (SELECT * FROM [ltd-hastus2].TEMPhastus2021TEMP.dbo.varpoint i
	   WHERE i.route_id = vsc.route_id AND i.stop_no = s.stop_no 
	   AND i.rvariant_id COLLATE SQL_Latin1_General_CP850_CI_AS = t.rvariant_id 
	   AND i.route_id COLLATE SQL_Latin1_General_CP850_CI_AS = t.route_id 
	   AND i.time_factor = 99) --exclude drop-off only trips
 GROUP BY p.poster_seq_no
         ,t.note

UPDATE @tbl_fns
   SET fn_text          = n.text
      ,fn_text_spanish  = s.note_text
      ,fn_text_combined = n.text + CASE WHEN s.note_text IS NULL THEN '' ELSE CHAR(13) + CHAR(10) + s.note_text END
  FROM      @tbl_fns                 t_fns
 INNER JOIN [ltd-hastus2].TEMPhastus2021TEMP.dbo.note          n ON n.note_id COLLATE SQL_Latin1_General_CP850_CI_AS = t_fns.trip_fn_id
  LEFT JOIN hastus.footnotes_in_spanish s ON s.note_id COLLATE SQL_Latin1_General_CP850_CI_AS  = t_fns.trip_fn_id

UPDATE o
   SET rn = wrn.rn
  FROM @tbl_fns o
 INNER JOIN (SELECT pn = poster_no, fn = trip_fn_id, rn = ROW_NUMBER() OVER (PARTITION BY poster_no ORDER BY trips DESC) FROM @tbl_fns WHERE fn_text NOT LIKE 'does not operate%') wrn ON wrn.pn = o.poster_no AND wrn.fn = o.trip_fn_id
 
UPDATE o
   SET rn = wrn.rn
  FROM @tbl_fns o
 INNER JOIN (SELECT pn = poster_no, fn = trip_fn_id, rn = @max_fn_chars_id +1 - ROW_NUMBER() OVER (PARTITION BY poster_no ORDER BY trips DESC) FROM @tbl_fns WHERE fn_text LIKE 'does not operate%') wrn ON wrn.pn = o.poster_no AND wrn.fn = o.trip_fn_id 
 
UPDATE @tbl_fns
   SET fn_char      = fns.the_value
      ,fn_char_sort = fns.the_id
  FROM      @tbl_fns               t_fns
 INNER JOIN hastus.bsi_footnote_chars fns ON fns.the_id = t_fns.rn
 
RETURN
END
GO
