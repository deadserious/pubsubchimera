unit chimera.pubsub.test.module;

interface

uses System.SysUtils, System.Classes, Web.HTTPApp, Web.HTTPProd,
  chimera.pubsub.producer;

type
  TWebModule1 = class(TWebModule)
    PubSubProducer1: TPubSubProducer;
    procedure WebModule1DefaultHandlerAction(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  WebModuleClass: TComponentClass = TWebModule1;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TWebModule1.WebModule1DefaultHandlerAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
begin
  Response.ContentStream := TFileStream.Create(ExtractFilePath(ParamStr(0))+'index.html', fmOpenRead or fmShareDenyNone);
  Response.ContentType := 'text/html';

end;

end.
