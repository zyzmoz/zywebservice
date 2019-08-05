unit webservice1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs,
  blcksock, sockets, Synautil, LazLogger, fpsimplejsonexport, fpjson,
  sqldb, strutils, Windows;

type
  TAction = (acInsert, acSelect, acUpdate, acDelete);

  TRoute = class(TObject)
    path: string;
    query: TSQLQuery;
    action: TAction;
  end;

  TFilter = class(TObject)
    Name: string;
    Value: variant;
  end;

  TResponse = (JSON, XML, SQL);


  { TWebService }
  TWebService = class(TComponent)
  private
    FHost: string;
    FPort: integer;
    FResponse: TResponse;
    procedure SetHost(AValue: string);
    procedure SetPort(AValue: integer);
    procedure SetResponse(AValue: TResponse);
  protected

  published
    property Host: string read FHost write SetHost;
    property Port: integer read FPort write SetPort;
    property Response: TResponse read FResponse write SetResponse default JSON;

  public
    constructor Create(AOwner: TComponent); override;
    procedure Start;
    procedure Stop;
    procedure Restart;
    procedure SetRoute(ARoute: string; AQuery: TSQLQuery; AAction: TAction = acSelect);
    procedure Send(AValue: string);
    function isActive(): boolean;


  end;

  { TWebServiceThread }

  TWebServiceThread = class(TThread)
  private
    FHost: string;
    FPort: integer;
    procedure AttendConnection(ASocket: TTCPBlockSocket);
    procedure SetHost(AValue: string);
    procedure SetPort(AValue: integer);
    function Get(URI, filter: string): string;
    function Post(URI: string; AData: string): string; overload;
    procedure Split(Delimiter: char; Str: string; ListOfStrings: TStrings);
    function ParseValue(str: string): variant;
  protected
    procedure Execute; override;
  published
    property Host: string read FHost write SetHost;
    property Port: integer read FPort write SetPort;
  end;

var
  ws: TWebServiceThread;
  ListenerSocket, ConnectionSocket: TTCPBlockSocket;
  routes: array of TRoute;
  filters: array of TFilter;
  s_routes: array of string;

procedure Register;

implementation


procedure Register;
begin
  {$I webservice1_icon.lrs}
  RegisterComponents('Web', [TWebService]);
end;

{ TWebService }

procedure TWebServiceThread.AttendConnection(ASocket: TTCPBlockSocket);
var
  timeout, i: integer;
  s, res: string;
  method, uri, protocol: string;
  OutputDataString: string;
  arq: TextFile;
  body: string;
  filter: string;
  message: TStringList;
  without_body: word;
  content: word = 0;
begin
  timeout := 120000;

  DebugLn('Received headers+document from browser:');

  //read request line
  s := ASocket.RecvString(timeout);

  DebugLn(s);
  method := fetch(s, ' ');
  uri := fetch(s, ' ');
  filter := '';
  if (uri.Contains('&')) then
  begin
    filter := copy(uri, pos('&', uri) + 1, Length(uri));
    uri := copy(uri, 0, pos('&', uri) - 1);
  end;
  protocol := fetch(s, ' ');

  //read request headers
  repeat
    s := ASocket.RecvString(Timeout);
    DebugLn(s);
  until s = '';

  if (method = 'POST') then
  begin
    res := ASocket.RecvPacket(timeout);
    body := copy(res, Pos('{', res) - 1, Length(res));
    if (body = '') then
      body := copy(res, Pos('[', res) - 1, Length(res));
    AssignFile(arq, 'headers.txt');
    Rewrite(arq);
    Write(arq, res);
    Close(arq);
  end;

  if (AnsiIndexStr(uri, s_routes) > -1) then
  begin
    if (AnsiIndexStr(uri, s_routes) = 0) then
    begin
      OutputDataString :=
        '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"' +
        ' "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">' +
        CRLF + '<html><h1>Server running at: ' + Host + ':' +
        IntToStr(Port) + '</h1></html>' + CRLF;

      // Write the headers back to the client
      ASocket.SendString('HTTP/1.0 200' + CRLF);
      ASocket.SendString('Content-type: Text/Html' + CRLF);
      ASocket.SendString('Content-length: ' + IntToStr(Length(OutputDataString)) + CRLF);
      ASocket.SendString('Connection: close' + CRLF);
      ASocket.SendString('Date: ' + Rfc822DateTime(now) + CRLF);
      ASocket.SendString('Server: Ws Lazarus' + CRLF);
      ASocket.SendString('' + CRLF);

      // Write the document back to the browser
      ASocket.SendString(OutputDataString);
    end
    else
    begin
      DebugLn(method);

      if (trim(method) = 'GET') then
        res := Get(uri, filter);

      if (trim(method) = 'POST') then
      begin
        res := Post(uri, body);
      end;

      OutputDataString := res;
      // Write the headers back to the client
      ASocket.SendString('HTTP/1.0 200' + CRLF);
      ASocket.SendString('Content-type: application/json' + CRLF);
      ASocket.SendString('Content-length: ' + IntToStr(Length(OutputDataString)) + CRLF);
      ASocket.SendString('Connection: close' + CRLF);
      ASocket.SendString('Date: ' + Rfc822DateTime(now) + CRLF);
      ASocket.SendString('Server: Ws Lazarus' + CRLF);
      ASocket.SendString('' + CRLF);

      // Write the document back to the browser
      ASocket.SendString(OutputDataString);
    end;
  end
  else
    ASocket.SendString('HTTP/1.0 404' + CRLF);
end;

procedure TWebServiceThread.SetHost(AValue: string);
begin
  if FHost = AValue then
    Exit;
  FHost := AValue;
end;

procedure TWebServiceThread.SetPort(AValue: integer);
begin
  if FPort = AValue then
    Exit;
  FPort := AValue;
end;

procedure TWebServiceThread.Execute;
begin
  ListenerSocket := TTCPBlockSocket.Create;
  ConnectionSocket := TTCPBlockSocket.Create;

  ListenerSocket.CreateSocket;
  ListenerSocket.setLinger(True, 1000);
  ListenerSocket.bind(Host, IntToStr(Port));
  ListenerSocket.HTTPTunnelIP := Host;
  ListenerSocket.HTTPTunnelPort := IntToStr(Port);
  ListenerSocket.listen;

  repeat
    if ListenerSocket.canread(1000) then
    begin
      ConnectionSocket.Socket := ListenerSocket.accept;
      debugLn('Attending Connection. Error code (0=Success): ' +
        IntToStr(ConnectionSocket.lasterror));
      AttendConnection(ConnectionSocket);
      ConnectionSocket.CloseSocket;
    end;
  until ws.Finished;
  //False;
  ListenerSocket.Free;
  ConnectionSocket.Free;

end;


procedure TWebService.SetHost(AValue: string);
begin
  if FHost = AValue then
    Exit;
  FHost := AValue;
end;

procedure TWebService.SetPort(AValue: integer);
begin
  if FPort = AValue then
    Exit;
  FPort := AValue;
end;

procedure TWebService.SetResponse(AValue: TResponse);
begin
  if FResponse = AValue then
    Exit;
  FResponse := AValue;
end;


function TWebServiceThread.Get(URI, filter: string): string;
var
  I, J: integer;
  jsonExp: TSimpleJSONExporter;
  st: TFileStream;
  bytes: TBytes;
  res, sql, paramField, orderBy: string;
  params: TStringList;
begin
  jsonExp := TSimpleJSONExporter.Create(nil);
  params := TStringList.Create;
  for I := 0 to Length(routes) - 1 do
  begin
    if (routes[I].path = uri) then
    begin
      sql := routes[i].query.SQL.Text;
      jsonExp.Dataset := routes[i].query;
      jsonExp.FileName := 'data.json';
      try
        routes[i].query.Close;

        Split('?', filter, params);
        if (params.Count > 0) then
        begin
          for J := 0 to params.Count - 1 do
          begin
            paramField := StringReplace(copy(params[J], 0, pos('=', params[J]) - 1),
              '?', '', [rfReplaceAll]);
            if ((paramField <> 'orderBy') and (paramField <> 'desc')) then
            begin
              if (J = 0) then
                routes[i].query.SQL.Add(' where ' + paramField)
              else
                routes[i].query.SQL.Add(' and ' + paramField);

              if (params[J].Contains('=%')) then
                routes[i].query.SQL.Add(' containing :PAR' + IntToStr(J))
              else
                routes[i].query.SQL.Add(' = :PAR' + IntToStr(J));

              routes[i].query.Params[J].Value :=
                ParseValue(StringReplace(copy(params[J], pos('=', params[J]) +
                1, Length(params[J])), '%', '', [rfReplaceAll]));
            end
            else
            begin
              if (paramField = 'orderBy') then
                orderBy := ' order by ' +
                  copy(params[J], pos('=', params[J]) + 1, Length(params[J]));

              if ((orderBy <> '') and (paramField = 'desc')) then
                orderBy := orderBy + ' desc';

            end;
          end;
          routes[i].query.SQL.Add(orderBy);
        end;

        routes[i].query.Open;
        jsonExp.Execute;
        st := TFileStream.Create('data.json', fmOpenRead or fmShareDenyWrite);
        if (st.Size > 0) then
        begin
          SetLength(bytes, st.Size);
          st.Read(bytes[0], st.Size);
        end;
        DeleteFile('data.json');
        res := StringReplace(TEncoding.ASCII.GetString(bytes), ';', ',', [rfReplaceAll]);
        res := StringReplace(res, #13#10, '', [rfReplaceAll]);
        res := copy(res, 0, pos(']', res) - 2);
        if (res = '') then
          res := res + '[';
        res := res + ']';
        FreeAndNil(jsonExp);
        FreeAndNil(st);
        routes[i].query.Close;
        routes[i].query.SQL.Text := sql;
        Result := res;
      except
        on E: Exception do
        begin
          Result := '{error: "' + e.Message + '"}';
          routes[i].query.SQL.Text := sql;
        end;
      end;
      break;
    end;
  end;
end;

function TWebServiceThread.Post(URI: string; AData: string): string;
var
  I, F: integer;
  jData: TJSONData;
  JSON: TJSONObject;
  auxSql, where: string;
begin
  jData := GetJSON(AData);
  JSON := TJSONObject(jData);

  for I := 0 to Length(routes) - 1 do
  begin
    if (routes[I].path = uri) then
    begin
      if (AData = '') then
        Result := '{error: "No Records found!"}';
      try
        case routes[I].action of
          acDelete:
          begin
            with routes[I] do
            begin
              try
                where := JSON.Get('where');
              except
                Result := '{error: "No where clause for delete method"}';
                Exit;
              end;

              auxSql := query.SQL.Text;
              if auxSql.Contains('where') then
                query.SQL.Add(' and ' + JSON.Get('where'))
              else
                query.SQL.Add(' where ' + JSON.Get('where'));
              query.Open;

              if (query.IsEmpty) then
              begin
                Result := '{error: "Record not found"}';
                Exit;
              end;

              query.Delete;

              (query.Transaction as TSQLTransaction).Commit;
              query.SQL.Text := auxSql;
              Result := '{action: "Delete", error: false}';
            end;
          end;
          acInsert:
          begin
            with routes[I] do
            begin
              query.Open;
              query.Insert;
              for F := 0 to query.FieldCount - 1 do
                query.Fields[F].Value := JSON.Get(LowerCase(query.Fields[F].FieldName));

              query.Post;
              query.ApplyUpdates();
              (query.Transaction as TSQLTransaction).Commit;
              Result := '{action: "Insert", error: false}';
            end;
          end;
          acUpdate:
          begin
            with routes[I] do
            begin
              try
                where := JSON.Get('where');
              except
                Result := '{error: "No where clause for update method"}';
                Exit;
              end;

              auxSql := query.SQL.Text;
              if auxSql.Contains('where') then
                query.SQL.Add(' and ' + JSON.Get('where'))
              else
                query.SQL.Add(' where ' + JSON.Get('where'));
              query.Open;

              if (query.IsEmpty) then
              begin
                Result := '{error: "Record not found"}';
                Exit;
              end;

              query.Edit;
              for F := 0 to query.FieldCount - 1 do
                query.Fields[F].Value := JSON.Get(LowerCase(query.Fields[F].FieldName));

              query.Post;
              query.ApplyUpdates();
              (query.Transaction as TSQLTransaction).Commit;
              query.SQL.Text := auxSql;
              Result := '{action: "Update", error: false}';
            end;
          end;
          else
            Result := '{error: "No Action Assigned!"}';
        end;

        //Result := AData;
      except
        on E: Exception do
          Result := '{error: "' + e.Message + '"}';
      end;
      break;
    end;
  end;
end;


procedure TWebServiceThread.Split(Delimiter: char; Str: string;
  ListOfStrings: TStrings);
begin
  ListOfStrings.Clear;
  ListOfStrings.Delimiter := Delimiter;
  ListOfStrings.StrictDelimiter := True;
  ListOfStrings.DelimitedText := Str;
end;

function TWebServiceThread.ParseValue(str: string): variant;
var
  I: integer;
  isInteger: boolean;
begin
  isInteger := True;
  for I := 0 to length(str) - 1 do
  begin
    if not (str[I] in ['0'..'9']) then
    begin
      isInteger := False;
      break;
    end;
  end;

  if (isInteger) then
    Result := StrToInt(str)
  else
    Result := str;

end;

constructor TWebService.Create(AOwner: TComponent);
var
  route: TRoute;
begin
  inherited Create(AOwner);
  route := TRoute.Create;
  SetLength(routes, Length(routes) + 1);
  SetLength(s_routes, Length(routes));
  route.path := '/';
  route.query := nil;
  s_routes[Length(routes) - 1] := route.path;
  routes[Length(routes) - 1] := route;

end;

procedure TWebService.Start;
begin
  ws := TWebServiceThread.Create(False);
  ws.Host := Host;
  ws.Port := Port;
  ws.Start;
end;

procedure TWebService.Stop;
begin
  if (ws <> nil) then
  begin
    ws.Terminate;

    //while not ws.Terminated do;
    //begin
    //  TerminateThread(ws.Handle,0);
    //end;

  end;
end;

procedure TWebService.Restart;
begin
  Stop;
  Start;
end;

procedure TWebService.SetRoute(ARoute: string; AQuery: TSQLQuery;
  AAction: TAction = acSelect);
var
  route: TRoute;
begin
  route := TRoute.Create;
  route.path := ARoute;
  route.query := AQuery;
  route.action := AAction;
  SetLength(routes, Length(routes) + 1);
  SetLength(s_routes, Length(routes));
  s_routes[Length(routes) - 1] := route.path;
  routes[Length(routes) - 1] := route;

end;


procedure TWebService.Send(AValue: string);
var
  timeout: integer;
  s: string;
  method, uri, protocol: string;
  OutputDataString: string;
  ResultCode: integer;
begin
  timeout := 120000;
  try
    if AValue <> '' then
    begin
      // Write the output document to the stream
      OutputDataString :=
        '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"' +
        ' "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">' +
        CRLF + '<html><h1>' + AValue + '</h1></html>' + CRLF;

      // Write the headers back to the client
      ConnectionSocket.SendString('HTTP/1.0 200' + CRLF);
      ConnectionSocket.SendString('Content-type: Text/Html' + CRLF);
      ConnectionSocket.SendString('Content-length: ' +
        IntToStr(Length(OutputDataString)) + CRLF);
      ConnectionSocket.SendString('Connection: close' + CRLF);
      ConnectionSocket.SendString('Date: ' + Rfc822DateTime(now) + CRLF);
      ConnectionSocket.SendString('Server: Ws Lazarus' + CRLF);
      ConnectionSocket.SendString('' + CRLF);

      // Write the document back to the browser
      ConnectionSocket.SendString(OutputDataString);
    end
    else
      ConnectionSocket.SendString('HTTP/1.0 404' + CRLF);

  except
  end;
end;

function TWebService.isActive(): boolean;
begin
  Result := not ws.Finished;
end;

end.
