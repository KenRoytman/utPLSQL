/* Formatted on 2001/07/13 12:29 (RevealNet Formatter v4.4.1) */
CREATE OR REPLACE PACKAGE BODY utrtestcase
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
$Log: ut_rtestcase.pkb,v $
Revision 1.3  2004/11/16 09:46:49  chrisrimmer
Changed to new version detection system.

Revision 1.2  2003/07/01 19:36:47  chrisrimmer
Added Standard Headers

************************************************************************/

   PROCEDURE initiate (
      run_id_in        IN   utr_testcase.run_id%TYPE,
      testcase_id_in   IN   utr_testcase.testcase_id%TYPE,
      start_on_in      IN   DATE := SYSDATE
   )
   IS
      &start_ge_8_1 
      PRAGMA autonomous_transaction;
   &start_ge_8_1
   BEGIN
      INSERT INTO utr_testcase
                  (run_id, testcase_id, start_on)
           VALUES (run_id_in, testcase_id_in, start_on_in);
   EXCEPTION
      WHEN DUP_VAL_ON_INDEX
      THEN
         -- Run has already been initiated. Ignore...
         NULL;
         &start_ge_8_1 
         ROLLBACK;
      &start_ge_8_1
      WHEN OTHERS
      THEN
         &start_ge_8_1 
         ROLLBACK;
         &start_ge_8_1
         utrerror.tc_report (
            run_id_in,
            testcase_id_in,
            SQLCODE,
            SQLERRM,
               'Unable to initiate testcase for run '
            || run_id_in
            || ' testcase ID '
            || testcase_id_in
         );
   END initiate;

   PROCEDURE terminate (
      run_id_in        IN   utr_testcase.run_id%TYPE,
      testcase_id_in   IN   utr_testcase.testcase_id%TYPE,
      end_on_in        IN   DATE := SYSDATE
   )
   IS
      &start_ge_8_1 
      PRAGMA autonomous_transaction;

      &start_ge_8_1
      CURSOR start_cur
      IS
         SELECT start_on, end_on
           FROM utr_testcase
          WHERE run_id = run_id_in
            AND testcase_id_in = testcase_id;

      rec        start_cur%ROWTYPE;
      l_status   utr_testcase.status%TYPE;
   BEGIN
      l_status := utresult2.run_status (run_id_in);
      OPEN start_cur;
      FETCH start_cur INTO rec;

      IF      start_cur%FOUND
          AND rec.end_on IS NULL
      THEN
         UPDATE utr_testcase
            SET end_on = end_on_in,
                status = l_status
          WHERE run_id = run_id_in
            AND testcase_id_in = testcase_id;
      ELSIF      start_cur%FOUND
             AND rec.end_on IS NOT NULL
      THEN
         -- Run is already terminated. Ignore...
         NULL;
      ELSE
         INSERT INTO utr_testcase
                     (run_id, testcase_id, status, end_on)
              VALUES (run_id_in, testcase_id_in, l_status, end_on_in);
      END IF;

      CLOSE start_cur;
      CLOSE start_cur;
      &start_ge_8_1 
      COMMIT;
   &start_ge_8_1
   EXCEPTION
      WHEN OTHERS
      THEN
         &start_ge_8_1 
         ROLLBACK;
         &start_ge_8_1
         utrerror.oc_report (
            run_id_in,
            testcase_id_in,
            SQLCODE,
            SQLERRM,
               'Unable to insert or update the utr_testcase table for run '
            || run_id_in
            || ' testcase ID '
            || testcase_id_in
         );
   END terminate;
END utrtestcase;
/
