/* Formatted on 2001/07/13 12:29 (RevealNet Formatter v4.4.1) */
CREATE OR REPLACE PACKAGE utsuite -- &start_ge_8_1 AUTHID CURRENT_USER &end_ge_8_1
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
$Log: ut_suite.pks,v $
Revision 1.4  2004/11/16 09:46:49  chrisrimmer
Changed to new version detection system.

Revision 1.3  2003/12/23 15:30:54  chrisrimmer
Added Jens Schauder's show_suites procedure

Revision 1.2  2003/07/01 19:36:47  chrisrimmer
Added Standard Headers

************************************************************************/

   /* Test suite API */

   c_name     CONSTANT CHAR (18) := 'TEST SUITE PACKAGE';
   c_abbrev   CONSTANT CHAR (5)  := 'SUITE';

   FUNCTION name_from_id (id_in IN ut_suite.id%TYPE)
      RETURN ut_suite.name%TYPE;

   FUNCTION id_from_name (name_in IN ut_suite.name%TYPE)
      RETURN ut_suite.id%TYPE;

   FUNCTION onerow (name_in IN ut_suite.name%TYPE)
      RETURN ut_suite%ROWTYPE;

   PROCEDURE ADD (
      name_in            IN   ut_suite.name%TYPE,
      desc_in            IN   VARCHAR2 := NULL,
      rem_if_exists_in   IN   BOOLEAN := TRUE,
	  per_method_setup_in in ut_suite.per_method_setup%type := null
	  
   );

   PROCEDURE rem (name_in IN ut_suite.name%TYPE);

   PROCEDURE rem (id_in IN ut_suite.id%TYPE);

   PROCEDURE upd (
      name_in         IN   ut_suite.name%TYPE,
      start_in             DATE,
      end_in               DATE,
      successful_in        BOOLEAN,
	  per_method_setup_in in ut_suite.per_method_setup%type := null
   );

   PROCEDURE upd (
      id_in           IN   ut_suite.id%TYPE,
      start_in             DATE,
      end_in               DATE,
      successful_in        BOOLEAN,
	  per_method_setup_in in ut_suite.per_method_setup%type := null
   );
   
   --Get a ref cursor returning suite details   
   FUNCTION suites (
      name_like_in   IN   VARCHAR2 := '%'
   )
      RETURN utconfig.refcur_t;
      
   --Simply write out the results of the above to dbms_output      
   PROCEDURE show_suites (name_like_in IN VARCHAR2 := '%');
         
END utsuite;
/
