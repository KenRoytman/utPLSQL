CREATE OR REPLACE PACKAGE BODY utresult
IS 
   
/************************************************************************
GNU General Public License for utPLSQL

Copyright (C) 2000-2003 
Steven Feuerstein and the utPLSQL Project
(steven@stevenfeuerstein.com)

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program (see license.txt); if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
************************************************************************
$Log: ut_result.pkb,v $
Revision 1.4  2004/11/16 09:46:49  chrisrimmer
Changed to new version detection system.

Revision 1.2  2003/07/01 19:36:47  chrisrimmer
Added Standard Headers

************************************************************************/

   resultindx            PLS_INTEGER;
   g_header_shown        BOOLEAN     := FALSE ;
   g_include_successes   BOOLEAN     := TRUE ;

   PROCEDURE include_successes
   IS
   BEGIN
      g_include_successes := TRUE ;
   END;

   PROCEDURE ignore_successes
   IS
   BEGIN
      g_include_successes := FALSE ;
   END;

   PROCEDURE showone (
      run_id_in   IN   utr_outcome.run_id%TYPE := NULL,
      indx_in     IN   PLS_INTEGER
   )
   IS
   BEGIN
      utreport.pl (results (indx_in).NAME || ': ' || results (indx_in).msg);
   END;

   PROCEDURE show (
      run_id_in   IN   utr_outcome.run_id%TYPE := NULL,
      reset_in    IN   BOOLEAN := FALSE
   )
   IS 
      indx     PLS_INTEGER               := results.FIRST;
      l_id     utr_outcome.run_id%TYPE   := NVL (run_id_in, utplsql2.runnum);
      norows   BOOLEAN;
   BEGIN
   
      utreport.before_results(run_id_in);
      
      FOR rec IN (SELECT   *
                      FROM utr_outcome
                     WHERE run_id = l_id
                  ORDER BY tc_run_id -- 2.0.9.1 
      )
      LOOP
         IF rec.status = utplsql.c_success
		    AND
			(NOT NVL (g_include_successes, FALSE )
             -- 2.0.10.1
			 OR
			 utconfig.showingfailuresonly)
         THEN
            -- Ignore in this case
            NULL;
         ELSIF utconfig.showingfailuresonly
		 THEN
            utreport.show_failure(rec);
		 ELSE
            utreport.show_result(rec);
         END IF;
      END LOOP;

      utreport.after_results(run_id_in);
      
      utreport.before_errors(run_id_in);

      FOR rec IN (SELECT *
                    FROM utr_error
                   WHERE run_id = l_id)
      LOOP
         utreport.show_error(rec);
      END LOOP;

      utreport.after_errors(run_id_in);
      
      IF reset_in
      THEN
         init;
      END IF;
   END;

   PROCEDURE showlast (run_id_in IN utr_outcome.run_id%TYPE := NULL)
   IS 
      indx   PLS_INTEGER := results.LAST;
   BEGIN
      -- 2.0.1 showheader;

      IF failure
      THEN
         showone (run_id_in, indx);
      END IF;
   END;

   PROCEDURE report (msg_in IN VARCHAR2)
   IS 
      indx   PLS_INTEGER := NVL (results.LAST, 0) + 1;
   BEGIN
      results (indx).NAME := utplsql.currcase.NAME;
      results (indx).indx := utplsql.currcase.indx;
      results (indx).msg := msg_in;
   END;

   PROCEDURE init (from_suite_in IN BOOLEAN := FALSE )
   IS
   BEGIN
      results.DELETE;
   -- Disable functionality 
   -- IF NOT from_suite_in THEN g_header_shown := FALSE; END IF;
   END;

   FUNCTION success (run_id_in IN utr_outcome.run_id%TYPE := NULL)
      RETURN BOOLEAN
   IS 
      l_count   PLS_INTEGER;
   BEGIN
      RETURN utresult2.run_succeeded (NVL (run_id_in, utplsql2.runnum));
   END;

   FUNCTION failure (run_id_in IN utr_outcome.run_id%TYPE := NULL)
      RETURN BOOLEAN
   IS
   BEGIN
      RETURN (NOT success (run_id_in));
   END;

   PROCEDURE firstresult (run_id_in IN utr_outcome.run_id%TYPE := NULL)
   IS
   BEGIN
      resultindx := results.FIRST;
   END;

   FUNCTION nextresult (run_id_in IN utr_outcome.run_id%TYPE := NULL)
      RETURN result_rt
   IS
   BEGIN
      /* 1.5.3 Must increment the counter */
      IF resultindx IS NULL
      THEN
         firstresult;
      ELSE
         resultindx := results.NEXT (resultindx);
      END IF;

      RETURN results (resultindx);
   END;

   FUNCTION nthresult (
      indx_in     IN   PLS_INTEGER,
      run_id_in   IN   utr_outcome.run_id%TYPE := NULL
   )
      RETURN result_rt
   IS 
      nullval   result_rt;
   BEGIN
      IF indx_in > resultcount OR NOT results.EXISTS (indx_in)
      THEN
         RETURN nullval;
      ELSE
         RETURN results (indx_in);
      END IF;
   END;

   PROCEDURE nextresult (
      name_out        OUT      VARCHAR2,
      msg_out         OUT      VARCHAR2,
      case_indx_out   OUT      PLS_INTEGER,
      run_id_in       IN       utr_outcome.run_id%TYPE := NULL
   )
   IS 
      rec   result_rt;
   BEGIN
      rec := nextresult;
      name_out := rec.NAME;
      msg_out := rec.msg;
      case_indx_out := rec.indx;
   END;

   PROCEDURE nthresult (
      indx_in         IN       PLS_INTEGER,
      name_out        OUT      VARCHAR2,
      msg_out         OUT      VARCHAR2,
      case_indx_out   OUT      PLS_INTEGER,
      run_id_in       IN       utr_outcome.run_id%TYPE := NULL
   )
   IS 
      rec   result_rt;
   BEGIN
      rec := nthresult (indx_in);
      name_out := rec.NAME;
      msg_out := rec.msg;
      case_indx_out := rec.indx;
   END;

   FUNCTION resultcount (run_id_in IN utr_outcome.run_id%TYPE := NULL)
      RETURN PLS_INTEGER
   IS
   BEGIN
      RETURN results.COUNT;
   END;
END utresult;
/
