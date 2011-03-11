/* Formatted on 2001/07/13 12:29 (RevealNet Formatter v4.4.1) */
CREATE OR REPLACE PACKAGE BODY uttest
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
$Log: ut_test.pkb,v $
Revision 1.5  2004/11/23 14:56:48  chrisrimmer
Moved dbms_pipe code into its own package.  Also changed some preprocessor flags

Revision 1.4  2004/11/16 09:46:49  chrisrimmer
Changed to new version detection system.

Revision 1.3  2004/07/14 17:01:57  chrisrimmer
Added first version of pluggable reporter packages

Revision 1.2  2003/07/01 19:36:47  chrisrimmer
Added Standard Headers

************************************************************************/

   FUNCTION name_from_id (id_in IN ut_test.id%TYPE)
      RETURN ut_test.name%TYPE
   IS
      retval   ut_test.name%TYPE;
   BEGIN
      SELECT name
        INTO retval
        FROM ut_test
       WHERE id = id_in;
      RETURN retval;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN NULL;
   END;

   FUNCTION id_from_name (name_in IN ut_test.name%TYPE)
      RETURN ut_test.id%TYPE
   IS
      retval   ut_test.id%TYPE;
   BEGIN
      SELECT name
        INTO retval
        FROM ut_test
       WHERE name = UPPER (name_in);
      RETURN retval;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN NULL;
   END;

   PROCEDURE ADD (
      package_in   IN   INTEGER,
      test_in      IN   VARCHAR2,
      desc_in      IN   VARCHAR2 := NULL,
      seq_in       IN   PLS_INTEGER := NULL
   )
   IS
      &start_ge_8_1 PRAGMA AUTONOMOUS_TRANSACTION; &start_ge_8_1
      v_id   ut_test.id%TYPE;
   BEGIN
      &start_ge_8_1 v_id := utplsql.seqval ('ut_test'); &start_ge_8_1
      &start_lt_8_1 SELECT ut_test_seq.NEXTVAL INTO v_id FROM dual; &end_lt_8_1

      INSERT INTO ut_test
                  (id, package_id, name, description,
                   seq)
           VALUES (v_id, package_in, UPPER (test_in), desc_in,
                   NVL (seq_in, 1));
   &start_ge_8_1 COMMIT; &start_ge_8_1
   EXCEPTION
      WHEN OTHERS
      THEN
         utreport.pl (   'Add test error: '
                     || SQLERRM);
         &start_ge_8_1 ROLLBACK; &start_ge_8_1
         RAISE;
   END;

   PROCEDURE ADD (
      package_in   IN   VARCHAR2,
      test_in      IN   VARCHAR2,
      desc_in      IN   VARCHAR2 := NULL,
      seq_in       IN   PLS_INTEGER := NULL
   )
   IS
   BEGIN
      ADD (utpackage.id_from_name (package_in), test_in, desc_in, seq_in);
   END;

   PROCEDURE rem (package_in IN INTEGER, test_in IN VARCHAR2)
   IS
   &start_ge_8_1 PRAGMA AUTONOMOUS_TRANSACTION; &start_ge_8_1
   BEGIN
      DELETE FROM ut_test
            WHERE package_id = package_in
              AND name LIKE UPPER (test_in);
   &start_ge_8_1 COMMIT; &start_ge_8_1
   EXCEPTION
      WHEN OTHERS
      THEN
         utreport.pl (   'Remove test error: '
                     || SQLERRM);
         &start_ge_8_1 ROLLBACK; &start_ge_8_1
         RAISE;
   END;

   PROCEDURE rem (package_in IN VARCHAR2, test_in IN VARCHAR2)
   IS
   BEGIN
      rem (utpackage.id_from_name (package_in), test_in);
   END;

   PROCEDURE upd (
      package_in      IN   INTEGER,
      test_in         IN   VARCHAR2,
      start_in             DATE,
      end_in               DATE,
      successful_in        BOOLEAN
   )
   IS
      &start_ge_8_1 PRAGMA AUTONOMOUS_TRANSACTION; &start_ge_8_1
      v_failure   PLS_INTEGER := 0;
   BEGIN
      IF NOT successful_in
      THEN
         v_failure := 1;
      END IF;

      UPDATE ut_test
         SET last_start = start_in,
             last_end = end_in,
             executions =   executions
                          + 1,
             failures =   failures
                        + v_failure
       WHERE package_id = package_in
         AND name = UPPER (test_in);
   &start_ge_8_1 COMMIT; &start_ge_8_1
   EXCEPTION
      WHEN OTHERS
      THEN
         utreport.pl (   'Update test error: '
                     || SQLERRM);
         &start_ge_8_1 ROLLBACK; &start_ge_8_1
         RAISE;
   END;

   PROCEDURE upd (
      package_in      IN   VARCHAR2,
      test_in         IN   VARCHAR2,
      start_in             DATE,
      end_in               DATE,
      successful_in        BOOLEAN
   )
   IS
   BEGIN
      upd (
         utpackage.id_from_name (package_in),
         test_in,
         start_in,
         end_in,
         successful_in
      );
   END;
END uttest;
/
