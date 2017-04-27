program lookupip;
(*
Copyright (C) 2017 Matthew Hipkin <http://www.matthewhipkin.co.uk>
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors
   may be used to endorse or promote products derived from this software without
   specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.

IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*)
{$mode objfpc}{$H+}

uses
 db, sqlite3ds, SysUtils, Classes, StrUtils;

function IP2Long(IPAddress: String): Int64;
var
  parts: TStrings;
begin
  parts := TStringList.Create;
  ExtractStrings(['.'], [], PChar(IPAddress), parts);
  if parts.Count = 4 then
  begin
    Result :=
    StrToInt64(parts[0]) shl 24 +
    StrToInt64(parts[1]) shl 16 +
    StrToInt64(parts[2]) shl 8 +
    StrToInt64(parts[3]);
  end
  else
  begin
    Result := 0;
  end;
  parts.Free;
end;

function LookupCountry(ip: String): String;
var
  dSrc: TSQLite3Dataset;
begin
  Result := '';
  dSrc := TSqlite3Dataset.Create(nil);
  with dSrc do
  begin
    FileName := 'geoip.db';
    TableName := 'geoip';
    Sql := 'SELECT country_code FROM geoip WHERE ip_from <= ' + IntToStr(IP2Long(ip)) + ' AND ip_to >= ' + IntToStr(IP2Long(ip));
    Open;
    First;
    Result := Fields[0].AsString;
  end;
  dSrc.Free;
end;

begin
  writeln(LookUpCountry(ParamStr(1)));
end.