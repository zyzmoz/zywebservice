unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  webservice1, sqldb, db, IBConnection;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    IBConnection1: TIBConnection;
    SQLQuery1: TSQLQuery;
    SQLQuery1ACEITADESCONTO: TStringField;
    SQLQuery1ACUMULADOFIDELIDADE: TLongintField;
    SQLQuery1ALIQICMS: TFloatField;
    SQLQuery1ALIQICMSFUF: TStringField;
    SQLQuery1ALTURA: TStringField;
    SQLQuery1ANP: TStringField;
    SQLQuery1ATIVO: TStringField;
    SQLQuery1BAIXAES: TStringField;
    SQLQuery1CFOP: TStringField;
    SQLQuery1CFOPDUF: TStringField;
    SQLQuery1CFOPFUF: TStringField;
    SQLQuery1CODBARRAS: TStringField;
    SQLQuery1CODCAIXA: TStringField;
    SQLQuery1CODFAMILIA: TLongintField;
    SQLQuery1CODGRUPO: TLongintField;
    SQLQuery1CODIGOFORNECEDOR: TLongintField;
    SQLQuery1CODIGOINTERNO: TLongintField;
    SQLQuery1CODIMPOSTO: TLongintField;
    SQLQuery1CODPACOTE: TStringField;
    SQLQuery1CODSETOR: TLongintField;
    SQLQuery1COD_FABRICANTE: TLongintField;
    SQLQuery1COFINS: TFloatField;
    SQLQuery1COMBUSTIVEL: TStringField;
    SQLQuery1COMPRIMENTO: TStringField;
    SQLQuery1CONSIGNADO: TFloatField;
    SQLQuery1CONTROLE: TLongintField;
    SQLQuery1CONTROLEVIRTUAL: TLongintField;
    SQLQuery1CSOSN: TStringField;
    SQLQuery1CST_COFINS: TStringField;
    SQLQuery1CST_IPI: TStringField;
    SQLQuery1CST_PIS: TStringField;
    SQLQuery1CUSTOMAXIMO: TFloatField;
    SQLQuery1DATAATUALIZACAO: TDateField;
    SQLQuery1DATACADASTRO: TDateField;
    SQLQuery1DATAFINALPROMOCAO: TDateField;
    SQLQuery1DATAINICIALPROMOCAO: TDateField;
    SQLQuery1DATAVALID: TDateField;
    SQLQuery1DATA_COMPNFE: TDateTimeField;
    SQLQuery1DESCONTAR: TStringField;
    SQLQuery1DESCRICAO: TStringField;
    SQLQuery1DESCRICAOABREVIADA: TStringField;
    SQLQuery1DESCRICAOLOJAVIRTUAL: TStringField;
    SQLQuery1DIFERENCA: TFloatField;
    SQLQuery1DTULTIMACOMPRA: TDateField;
    SQLQuery1DTULTIMAVENDA: TDateField;
    SQLQuery1ENVIARBALANCA: TStringField;
    SQLQuery1ESTOQUE: TStringField;
    SQLQuery1ESTOQUECONSIGNADO: TFloatField;
    SQLQuery1ESTOQUEE: TFloatField;
    SQLQuery1ESTOQUEMAXIMO: TFloatField;
    SQLQuery1ESTOQUEMINIMO: TFloatField;
    SQLQuery1ESTOQUESALDO: TFloatField;
    SQLQuery1ESTOQUE_DEPOSITO: TFloatField;
    SQLQuery1FABRICANTE: TStringField;
    SQLQuery1FALTANTE: TStringField;
    SQLQuery1GERAFIDELIDADE: TStringField;
    SQLQuery1ICMS: TFloatField;
    SQLQuery1INVENTARIO: TFloatField;
    SQLQuery1IPI: TFloatField;
    SQLQuery1LARGURA: TStringField;
    SQLQuery1LUCRO: TFloatField;
    SQLQuery1LUCROFIXO: TFloatField;
    SQLQuery1LVCX: TStringField;
    SQLQuery1LVPT: TStringField;
    SQLQuery1LVUN: TStringField;
    SQLQuery1NCM: TStringField;
    SQLQuery1NCM_EX: TLongintField;
    SQLQuery1NUMEROTECLA: TLongintField;
    SQLQuery1OBSERVACAO: TStringField;
    SQLQuery1ORIGEM_MERCADORIA: TStringField;
    SQLQuery1PESO: TStringField;
    SQLQuery1PIS: TFloatField;
    SQLQuery1PIZZA: TStringField;
    SQLQuery1PRODUTOS: TStringField;
    SQLQuery1QTDCAIXA: TFloatField;
    SQLQuery1QTDPACOTE: TFloatField;
    SQLQuery1REFERENCIA: TStringField;
    SQLQuery1SITRIBFUF: TStringField;
    SQLQuery1SITTRIBENTRE: TStringField;
    SQLQuery1SITTRIBUTARIA: TStringField;
    SQLQuery1SOMENTEENTRADA: TStringField;
    SQLQuery1SUBGRUPO: TLongintField;
    SQLQuery1TAXAENTREGAINDIVIDUAL: TStringField;
    SQLQuery1TECLA: TLongintField;
    SQLQuery1TIPOIMPRESSORA: TStringField;
    SQLQuery1UNIDADE: TStringField;
    SQLQuery1USACARDAPIO: TStringField;
    SQLQuery1VALIDADE: TLongintField;
    SQLQuery1VALORCAIXA: TFloatField;
    SQLQuery1VALORCUSTO: TFloatField;
    SQLQuery1VALORDOMINGO: TFloatField;
    SQLQuery1VALORGELADO: TFloatField;
    SQLQuery1VALORGIGANTE: TFloatField;
    SQLQuery1VALORGRANDE: TFloatField;
    SQLQuery1VALORMEDIO: TFloatField;
    SQLQuery1VALORPACOTE: TFloatField;
    SQLQuery1VALORPEQUENO: TFloatField;
    SQLQuery1VALORQUARTA: TFloatField;
    SQLQuery1VALORQUINTA: TFloatField;
    SQLQuery1VALORSABADO: TFloatField;
    SQLQuery1VALORSEGUNDA: TFloatField;
    SQLQuery1VALORSEXTA: TFloatField;
    SQLQuery1VALORTERCA: TFloatField;
    SQLQuery1VALORVENDA: TFloatField;
    SQLQuery1VENDAEXTERNA: TFloatField;
    SQLQuery1VENDAPROMO: TFloatField;
    SQLQuery1VENDEKGBAIXAUN: TStringField;
    SQLQuery1VENDEPORPESO: TStringField;
    SQLQuery1VERIFICAESTOQUE: TStringField;
    SQLQuery1VLULTIMACOMPRA: TFloatField;
    SQLQuery1VLULTIMAVENDA: TFloatField;
    SQLTransaction1: TSQLTransaction;
    WebService1: TWebService;
    procedure Button1Click(Sender: TObject);
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
  WebService1.SetRoute('/lol', SQLQuery1);
  WebService1.Start;
end;

end.

