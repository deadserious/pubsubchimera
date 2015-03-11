program chimera_webbroker_server_persistent;
{$APPTYPE GUI}

uses
  Vcl.Forms,
  Web.WebReq,
  IdHTTPWebBrokerBridge,
  chimera.pubsub.test.form in '..\webbroker\chimera.pubsub.test.form.pas' {Form1},
  chimera.pubsub.test.module in '..\webbroker\chimera.pubsub.test.module.pas' {WebModule1: TWebModule},
  chimera.pubsub.test.data in 'chimera.pubsub.test.data.pas' {DataModule1: TDataModule};

{$R *.res}

begin
  if WebRequestHandler <> nil then
    WebRequestHandler.WebModuleClass := WebModuleClass;
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TDataModule1, DataModule1);
  Application.Run;
end.


