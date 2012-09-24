function str= str_escapePrintf(str)
%ESCAPE_PRINTF - Insert Escape Charaters for Non-Formatted FPRINTF.
%
%Synopsis:
%  STROUT= str_escapePrintf(STR_IN)


str= strrep(str, '\','\\');
str= strrep(str, '%','%%');
