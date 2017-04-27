program importgeocsv;
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
  SysUtils, Classes, StrUtils, sqldb, sqlite3conn;

var
  db: TSQLite3Connection;
  trans: TSQLTransaction;
  query: TSQLQuery;
  items: TStrings;
  F: TextFile;
  l: String;
  ip_from: Int64;
  ip_to: Int64;
  country_code: String;
  country_name: String;

begin
  if FileExists('geoip.db') then DeleteFile('geoip.db');
  db := TSQLite3Connection.Create(nil);
  trans := TSQLTransaction.Create(nil);
  query := TSQLQuery.Create(nil);
  query.Database := db;
  query.Transaction := trans;
  db.Transaction := trans;
  db.Username := '';
  db.Password := '';
  db.DatabaseName := 'geoip.db';
  db.Open;
  trans.Active := true;
  db.ExecuteDirect('CREATE TABLE "geoip" ("ip_from" BIGINT, "ip_to" BIGINT, "country_code" Char(2), "country_name" Char(255))');
  trans.Commit;
  AssignFile(F,'IP2LOCATION-LITE-DB1.CSV');
  Reset(F);
  trans.Active := false;
  trans.Action := caCommit;
  trans.StartTransaction;
  query.InsertSQL.Text := 'INSERT INTO "geoip" VALUES (:ip_from,:ip_to,:country_code,:country_name)';
  query.SQL.Text := 'SELECT * FROM "geoip"';
  query.ReadOnly := false;
  query.Open;
  items := TStringList.Create;
  while not eof(F) do
  begin
    Readln(F,l);
    items.Clear;
    items.Delimiter := ',';
    items.QuoteChar := '"';
    items.DelimitedText := l;
    ip_from := StrToInt64(AnsiReplaceStr(items[0],'"',''));
    ip_to := StrToInt64(AnsiReplaceStr(items[1],'"',''));
    country_code := AnsiReplaceStr(items[2],'"','');
    country_name := AnsiReplaceStr(items[3],'"','');
    with query do
    begin
      try
      Insert;
      FieldByName('ip_from').AsLargeInt := ip_from;
      FieldByName('ip_to').AsLargeInt := ip_to;
      FieldByName('country_code').AsString := country_code;
      FieldByName('country_name').AsString := country_name;
      Post;
      ApplyUpdates;
      except
        writeln(ip_from,' ',ip_to,' ',country_code,' ',country_name);
      end;
    end;
  end;
  CloseFile(F);
  query.Close;
  trans.Active := false;
  db.Close;
  query.Free;
  trans.Free;
  db.Free;
  items.Free;
end.
