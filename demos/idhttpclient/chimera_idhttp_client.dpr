program chimera_idhttp_client;

uses
  Vcl.Forms,
  chimera.pubsub.demos.client.form in 'chimera.pubsub.demos.client.form.pas' {Form2};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.
