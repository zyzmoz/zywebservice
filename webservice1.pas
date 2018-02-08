unit webservice1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs,
  blcksock, sockets, Synautil, LazLogger, fpsimplejsonexport, sqldb, strutils;

type
  TRoute = class(TObject)
    path: string;
    query: TSQLQuery;
  end;

  { TWebService }
  TWebService = class(TComponent)
  private
    FHost: string;
    FPort: integer;
    procedure SetHost(AValue: string);
    procedure SetPort(AValue: integer);
  protected

  published
    property Host: string read FHost write SetHost;
    property Port: integer read FPort write SetPort;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Start;
    procedure SetRoute(ARoute: string; AQuery: TSQLQuery);
    procedure Send(AValue: string);


  end;

  { TWebServiceThread }

  TWebServiceThread = class(TThread)
  private
    FHost: string;
    FPort: integer;
    procedure AttendConnection(ASocket: TTCPBlockSocket);
    procedure SetHost(AValue: string);
    procedure SetPort(AValue: integer);
    function Get(URI: string): string;
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
  timeout: integer;
  s, res: string;
  method, uri, protocol: string;
  OutputDataString: string;
  ResultCode: integer;

begin
  timeout := 120000;

  DebugLn('Received headers+document from browser:');

  //read request line
  s := ASocket.RecvString(timeout);
  DebugLn(s);
  method := fetch(s, ' ');
  uri := fetch(s, ' ');
  protocol := fetch(s, ' ');

  //read request headers
  repeat
    s := ASocket.RecvString(Timeout);
    DebugLn(s);
  until s = '';

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
      if (trim(method) = 'get') then
        res := Get(uri);
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

  // Now write the document to the output stream
  //if uri = '/' then
  //begin
  //  // Write the output document to the stream
  //  OutputDataString :=
  //    '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"' +
  //    ' "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">' +
  //    CRLF + '<html><h1>Server running at: ' + Host + ':' +
  //    IntToStr(Port) + '</h1></html>' + CRLF;

  //  // Write the headers back to the client
  //  ASocket.SendString('HTTP/1.0 200' + CRLF);
  //  ASocket.SendString('Content-type: Text/Html' + CRLF);
  //  ASocket.SendString('Content-length: ' + IntToStr(Length(OutputDataString)) + CRLF);
  //  ASocket.SendString('Connection: close' + CRLF);
  //  ASocket.SendString('Date: ' + Rfc822DateTime(now) + CRLF);
  //  ASocket.SendString('Server: Ws Lazarus' + CRLF);
  //  ASocket.SendString('' + CRLF);

  //  // Write the document back to the browser
  //  ASocket.SendString(OutputDataString);
  //end
  //else
  //  ASocket.SendString('HTTP/1.0 404' + CRLF);

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
  ListenerSocket.setLinger(True, 10);
  ListenerSocket.bind(Host, IntToStr(Port));
  ListenerSocket.HTTPTunnelIP := '192.168.0.12';
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
  until False;

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

function TWebServiceThread.Get(URI: string): string;
var
  I : integer;
  jsonExp: TSimpleJSONExporter;
  st: TFileStream;
  bytes: TBytes;
begin
  jsonExp := TSimpleJSONExporter.Create(nil);
  for I := 0 to Length(routes) - 1 do
  begin
    if (routes[I].path = uri) then
    begin
      jsonExp.Dataset := routes[i].query;
      jsonExp.FileName := 'data.json';
      try
        routes[i].query.Open;
        jsonExp.Execute;
        st := TFileStream.Create('data.json', fmOpenRead or fmShareDenyWrite);
        if (st.Size > 0) then
        begin
          SetLength(bytes, st.Size);
          st.Read(bytes[0], st.Size);
        end;
         Result := TEncoding.ASCII.GetString(bytes);


      except
        on E: Exception do
          Result := '{error: "' + e.Message + '"}';
      end;
      break;
    end;
  end;
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

procedure TWebService.SetRoute(ARoute: string; AQuery: TSQLQuery);
var
  route: TRoute;
begin
  route := TRoute.Create;
  route.path := ARoute;
  route.query := AQuery;
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

end.
