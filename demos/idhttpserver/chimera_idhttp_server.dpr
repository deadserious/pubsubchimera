program chimera_idhttp_server;

uses
  Vcl.Forms,
  chimera.pubsub.demos.idhttp.form in 'chimera.pubsub.demos.idhttp.form.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
