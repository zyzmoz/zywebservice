unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  webservice1, sqldb, db, fpsimplejsonexport, IBConnection;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    CheckBox1: TCheckBox;
    IBConnection1: TIBConnection;
    SQLQuery1: TSQLQuery;
    SQLQuery1DESCRIPTION: TStringField;
    SQLQuery1EAN: TStringField;
    SQLQuery1GROUP: TLongintField;
    SQLQuery1PIZZA: TLongintField;
    SQLQuery1VALUE: TFloatField;
    SQLTransaction1: TSQLTransaction;
    WebService1: TWebService;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.Button1Click(Sender: TObject);
begin
  WebService1.Start;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  WebService1.Stop;
end;

procedure TForm1.ComboBox1Change(Sender: TObject);
begin

end;

procedure TForm1.FormShow(Sender: TObject);
begin
  WebService1.SetRoute('/lol', SQLQuery1);
end;

end.

