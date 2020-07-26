with UnZip; use UnZip;
with Ada.Command_Line;
with GNAT.Exception_Actions;
with Ada.Exceptions;
with Ada.Text_IO; use Ada.Text_IO;

procedure Test_Extract_AFL is
begin
  Extract (From                 => Ada.Command_Line.Argument (1),
           Options              => (Test_Only => True, others => False),
           Password             => "",
           File_System_Routines => Null_routines);
exception
  when Occurence : others  =>
     Put_Line ("exception occured [" & Ada.Exceptions.Exception_Name (Occurence)
               & "] [" & Ada.Exceptions.Exception_Message (Occurence)
               & "] [" & Ada.Exceptions.Exception_Information (Occurence) & "]");
     GNAT.Exception_Actions.Core_Dump (Occurence);
end Test_Extract_AFL;
