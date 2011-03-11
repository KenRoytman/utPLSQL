/* Formatted on 2001/07/13 12:29 (RevealNet Formatter v4.4.1) */
CREATE OR REPLACE PACKAGE BODY utsuite
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
$Log: ut_suite.pkb,v $
Revision 1.6  2004/11/23 14:56:48  chrisrimmer
Moved dbms_pipe code into its own package.  Also changed some preprocessor flags

Revision 1.5  2004/11/16 09:46:49  chrisrimmer
Changed to new version detection system.

Revision 1.4  2004/07/14 17:01:57  chrisrimmer
Added first version of pluggable reporter packages

Revision 1.3  2003/12/23 15:30:53  chrisrimmer
Added Jens Schauder's show_suites procedure

Revision 1.2  2003/07/01 19:36:47  chrisrimmer
Added Standard Headers

************************************************************************/

   FUNCTION name_from_id (id_in IN ut_suite.id%TYPE)
      RETURN ut_suite.name%TYPE
   IS
      retval   ut_suite.name%TYPE;
   BEGIN
      SELECT name
        INTO retval
        FROM ut_suite
       WHERE id = id_in;
      RETURN retval;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN NULL;
   END;

   FUNCTION id_from_name (name_in IN ut_suite.name%TYPE)
      RETURN ut_suite.id%TYPE
   IS
      retval   ut_suite.id%TYPE;
   BEGIN
      SELECT id
        INTO retval
        FROM ut_suite
       WHERE name = UPPER (name_in);
      RETURN retval;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN NULL;
   END;

   FUNCTION onerow (name_in IN ut_suite.name%TYPE)
      RETURN ut_suite%ROWTYPE
   IS
      retval   ut_suite%ROWTYPE;
   BEGIN
      SELECT *
        INTO retval
        FROM ut_suite
       WHERE name = UPPER (name_in);
      RETURN retval;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN retval;
   END;

   PROCEDURE ADD (
      name_in            IN   ut_suite.name%TYPE,
      desc_in            IN   VARCHAR2 := NULL,
      rem_if_exists_in   IN   BOOLEAN := TRUE,
	  per_method_setup_in in ut_suite.per_method_setup%type := null
   )
   IS
      &start_ge_8_1 PRAGMA AUTONOMOUS_TRANSACTION; &start_ge_8_1
      v_id   ut_suite.id%TYPE;
   BEGIN
      utrerror.assert (name_in IS NOT NULL, 'Suite names cannot be null.');

      &start_ge_8_1 v_id := utplsql.seqval ('ut_suite'); &start_ge_8_1
      &start_lt_8_1 SELECT ut_suite_seq.NEXTVAL INTO v_id FROM dual; &end_lt_8_1

      INSERT INTO ut_suite
                  (id, name, description, executions, failures,per_method_setup)
           VALUES (v_id, UPPER (name_in), desc_in, 0, 0,per_method_setup_in);
   &start_ge_8_1 COMMIT; &start_ge_8_1
   EXCEPTION
      WHEN DUP_VAL_ON_INDEX
      THEN
         IF rem_if_exists_in
         THEN
            rem (name_in);
            ADD (name_in, desc_in, per_method_setup_in => per_method_setup_in);
         ELSE
            &start_ge_8_1 ROLLBACK; &start_ge_8_1
            RAISE;
         END IF;
      WHEN OTHERS
      THEN
      
        IF utrerror.uterrcode = utrerror.assertion_failure
         THEN
                     &start_ge_8_1 ROLLBACK; &start_ge_8_1
                     raise;
         ELSE
                  &start_ge_8_1 ROLLBACK; &start_ge_8_1
         utrerror.report_define_error (
            c_abbrev,
               'Suite '
            || name_in
         );
         END IF;

   END;

   PROCEDURE rem (id_in IN ut_suite.id%TYPE)
   IS
   &start_ge_8_1 PRAGMA AUTONOMOUS_TRANSACTION; &start_ge_8_1
   BEGIN
      -- V1 compatibility
      DELETE FROM ut_package
            WHERE suite_id = id_in;

      DELETE FROM ut_suite_utp
            WHERE suite_id = id_in;

      DELETE FROM ut_suite
            WHERE id = id_in;
   &start_ge_8_1 COMMIT; &start_ge_8_1
   EXCEPTION
      WHEN OTHERS
      THEN
         utreport.pl (   'Remove suite error: '
                     || SQLERRM);
         &start_ge_8_1 ROLLBACK; &start_ge_8_1
         RAISE;
   END;

   PROCEDURE rem (name_in IN ut_suite.name%TYPE)
   IS
      &start_ge_8_1 PRAGMA AUTONOMOUS_TRANSACTION; &start_ge_8_1
      v_id   ut_suite.id%TYPE;
   BEGIN
      rem (id_from_name (name_in));
   END;

   PROCEDURE upd (
      id_in           IN   ut_suite.id%TYPE,
      start_in             DATE,
      end_in               DATE,
      successful_in        in BOOLEAN,
	  per_method_setup_in in ut_suite.per_method_setup%type := null
   )
   IS
      &start_ge_8_1 PRAGMA AUTONOMOUS_TRANSACTION; &start_ge_8_1
      l_status    VARCHAR2 (100) := utplsql.c_success;
      v_failure   PLS_INTEGER    := 0;

      PROCEDURE do_upd
      IS
      BEGIN
         UPDATE ut_suite
            SET last_status = l_status,
                last_start = start_in,
                last_end = end_in,
				per_method_setup = per_method_setup_in,
                executions =   NVL (executions, 0)
                             + 1,
                failures =   NVL (failures, 0)
                           + v_failure
          WHERE id = id_in;
      END;
   BEGIN
      IF NOT successful_in
      THEN
         v_failure := 1;
         l_status := utplsql.c_failure;
      END IF;

      do_upd;

      IF SQL%ROWCOUNT = 0
      THEN
         ADD (
            name_in=> name_from_id (id_in),
            desc_in=>    'No description for "'
                      || name_from_id (id_in)
                      || '"',
            rem_if_exists_in=> FALSE,
			per_method_setup_in=>per_method_setup_in
         );
         do_upd;
      END IF;
   &start_ge_8_1 COMMIT; &start_ge_8_1
   EXCEPTION
      WHEN OTHERS
      THEN
         utreport.pl (   'Update suite error: '
                     || SQLERRM);
         &start_ge_8_1 ROLLBACK; &start_ge_8_1
         RAISE;
   END;

   PROCEDURE upd (
      name_in         IN   ut_suite.name%TYPE,
      start_in             DATE,
      end_in               DATE,
      successful_in        BOOLEAN,
	  per_method_setup_in in ut_suite.per_method_setup%type := null
   )
   IS
   BEGIN
      upd (id_from_name (name_in), start_in, end_in, successful_in,
	  per_method_setup_in);
   END;
   
   FUNCTION suites (name_like_in IN VARCHAR2 := '%')
      RETURN utconfig.refcur_t
   IS
      retval   utconfig.refcur_t;
   BEGIN
      OPEN retval FOR
         SELECT *
           FROM ut_suite
          WHERE NAME LIKE UPPER (name_like_in);
      RETURN retval;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN retval;
   END;
   
   --Simply write out the results of the above to dbms_output
   PROCEDURE show_suites (name_like_in IN VARCHAR2 := '%')
   IS
     indent VARCHAR2(20) := ' ';
     suites_cur utconfig.refcur_t;
     suite ut_suite%ROWTYPE;

     CURSOR packages_cur (pi_id ut_suite.id%TYPE) IS
        SELECT * FROM ut_package
        WHERE suite_id = pi_id;
  
   BEGIN
      suites_cur := suites(name_like_in);
      
      LOOP
         FETCH suites_cur INTO suite;
         EXIT WHEN suites_cur%NOTFOUND;
         dbms_output.put_line(suite.name);
         FOR pack IN packages_cur(suite.id) LOOP
            dbms_output.put_line(indent || pack.name);
         END LOOP;
      END LOOP;
   END show_suites;
   
END utsuite;
/
