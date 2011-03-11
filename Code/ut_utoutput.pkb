CREATE OR REPLACE PACKAGE BODY ut_utoutput
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
$Log: ut_utoutput.pkb,v $
Revision 1.4  2004/11/16 09:46:49  chrisrimmer
Changed to new version detection system.

Revision 1.3  2003/07/01 19:36:47  chrisrimmer
Added Standard Headers

************************************************************************/

   PROCEDURE clear_buffer
   IS
     lines number;
     buffer DBMS_OUTPUT.CHARARR;     
   BEGIN
     lines := 1000000;
     dbms_output.get_lines(buffer, lines);
   END;

   PROCEDURE ut_setup
   IS
   BEGIN
     dbms_output.enable(1000000);
   END;
   
   PROCEDURE ut_teardown
   IS
   BEGIN
      NULL;
   END;

   PROCEDURE ut_count
   IS
   BEGIN
     
     clear_buffer;
     
     utassert.eq('Count Empty buffer', utoutput.count, 0);
     
     dbms_output.put_line('XYZ');      
     
     utassert.eq('Count Single Line', utoutput.count, 1);     
     
     utassert.eq('Count Single Line Still Present', utoutput.count, 1);
     
     dbms_output.put_line('ABC');      
     
     utassert.eq('Count Two Lines', utoutput.count, 2);     

     clear_buffer;
          
   END ut_count;

   PROCEDURE ut_extract
   IS
   
     buf dbms_output.CHARARR;
     buf2 dbms_output.CHARARR;
   
   BEGIN
     
     utoutput.replace;
     clear_buffer;
     
     dbms_output.put_line('Alpha');      
     dbms_output.put_line('Beta');
     dbms_output.put_line('Gamma');
     
     utoutput.save;
     utassert.eq('Pull one line', utoutput.extract(max_lines_in => 1, 
                                                   save_in => FALSE), 1);
     utassert.eq('Pull two lines', utoutput.extract(buffer_out => buf, 
                                                    max_lines_in => 2, 
                                                    save_in => FALSE), 2);
     utassert.eq('How Many Lines Pulled', buf.COUNT, 2);
     utassert.eq('First Line Pulled', buf(buf.FIRST), 'Beta');
     utassert.eq('Second Line Pulled', buf(buf.NEXT(buf.FIRST)), 'Gamma');

     clear_buffer;
     
     dbms_output.put_line('Al');      
     dbms_output.put_line('Ben');
     dbms_output.put_line('Carol');
     dbms_output.put_line('Donna');
     
     utoutput.extract(max_lines_in => 1);
     utoutput.extract(buffer_out => buf);
     
     utassert.eq('2: How Many Lines Pulled', buf.COUNT, 3);
     utassert.eq('2: First Line Pulled', buf(buf.FIRST), 'Ben');
     utassert.eq('2: Second Line Pulled', buf(buf.NEXT(buf.FIRST)), 'Carol');
     utassert.eq('2: Third Line Pulled', buf(buf.NEXT(buf.NEXT(buf.FIRST))), 'Donna');
     
     utoutput.replace;
     
     utassert.eq('Count Lines Collected and Replaced', utoutput.COUNT, 4);
     
     clear_buffer;
     
   END ut_extract;

   PROCEDURE ut_nextline
   IS
   BEGIN
     
     clear_buffer;
     
     utassert.isnull('NextLine Empty Buffer', utoutput.nextline(raise_exc_in => FALSE, save_in => FALSE));
     utassert.throws('NextLine Empty Buffer with Exception', 
                     'declare 
                        v varchar2(2000);
                      begin 
                        v := utoutput.nextline(raise_exc_in => TRUE, save_in => FALSE); 
                      end;',
                     'utoutput.EMPTY_OUTPUT_BUFFER');

     dbms_output.put_line('DEF');
     dbms_output.put_line('GHI');     
     
     utassert.eq('NextLine Typical 1', utoutput.nextline(raise_exc_in => FALSE, save_in => FALSE), 'DEF');
     utassert.eq('NextLine Typical 2', utoutput.nextline(raise_exc_in => FALSE, save_in => FALSE), 'GHI');                                   
     
     utassert.isnull('NextLine Empty Buffer Again', utoutput.nextline(raise_exc_in => FALSE, save_in => FALSE));     

     clear_buffer;
     
   END ut_nextline;

   PROCEDURE ut_replace
   IS
    
     dummy VARCHAR2(2000);
   
   BEGIN
     
     utoutput.replace;
     clear_buffer;
     
     --Put in some text, extract, then replace it
     dbms_output.put_line('JKL');
     dummy := utoutput.nextline(raise_exc_in => FALSE, save_in => TRUE);
     utoutput.replace;
     
     --Extract again, but don't save
     dummy := utoutput.nextline(raise_exc_in => FALSE, save_in => FALSE);
     utassert.eq('NextLine after replace', dummy, 'JKL');

     --Try replacing when there should be nothing to replace
     utoutput.replace;          

     dummy := utoutput.nextline(raise_exc_in => FALSE, save_in => FALSE);
     utassert.isnull('NextLine after empty replace', dummy);

     dbms_output.put_line('MNO');
     dbms_output.put_line('PQR');
     
     --Pull out all the data, but save it
     utoutput.save;
     utoutput.extract(max_lines_in => 1000);
     utoutput.nosave;
     
     --It should be empty now
     dummy := utoutput.nextline(raise_exc_in => FALSE);
     utassert.isnull('NextLine after full extract', dummy);
     
     --Put it back
     utoutput.replace;
     
     utassert.eq('Count after multi-replace', utoutput.count, 2);
     
     utassert.eq('NextLine after multi-replace', utoutput.nextline, 'MNO');
     utassert.eq('NextLine again after multi-replace', utoutput.nextline, 'PQR');
     
     --Make sure all is clear
     utoutput.replace;
     clear_buffer;
     
   END ut_replace;

   PROCEDURE ut_saving
   IS
   BEGIN
     
     utoutput.save;
     
     utassert.this('Saving Turned On', utoutput.saving);

     utoutput.nosave;
     
     utassert.this('Saving Turned Off', NOT utoutput.saving);

     utoutput.save;
     
     utassert.this('Saving Turned Back On', utoutput.saving);
     
   END ut_saving;
   
END ut_utoutput;

/
