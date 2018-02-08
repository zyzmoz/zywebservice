{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit zyWebService;

{$warn 5023 off : no warning about unused units}
interface

uses
  webservice1, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('webservice1', @webservice1.Register);
end;

initialization
  RegisterPackage('zyWebService', @Register);
end.
