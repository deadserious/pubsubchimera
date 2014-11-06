unit chimera.pubsub.demos.idhttp.form;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, IdBaseComponent, IdComponent, IdCookie,
  IdCustomTCPServer, IdCustomHTTPServer, chimera.pubsub.server.idhttp, IdContext,
  Vcl.StdCtrls, WinAPI.ShellAPI;

type
  TForm1 = class(TForm)
    PubSubHTTPServer1: TPubSubHTTPServer;
    Button1: TButton;
    procedure PubSubHTTPServer1Session(Sender: TObject;
      Request: TIdHTTPRequestInfo; Response: TIdHTTPResponseInfo;
      var SessionID: string);
    procedure FormCreate(Sender: TObject);
    procedure PubSubHTTPServer1CommandGet(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
  ShellExecute(Self.Handle, 'open', 'http://127.0.0.1:8080/','','',SW_SHOWMAXIMIZED);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  PubSubHTTPServer1.DefaultPort := 8080;
  PubSubHTTPServer1.Active := True;
end;

procedure TForm1.PubSubHTTPServer1CommandGet(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
begin
  if ARequestInfo.Document = '/' then
  begin
    AResponseInfo.ContentStream := TFileStream.Create(ExtractFilePath(ParamStr(0))+'index.html', fmOpenRead or fmShareDenyNone);
    AResponseInfo.ContentType := 'text/html';

  end;
end;

procedure TForm1.PubSubHTTPServer1Session(Sender: TObject;
  Request: TIdHTTPRequestInfo; Response: TIdHTTPResponseInfo;
  var SessionID: string);
var
  cookie : TIdCookie;
begin
  cookie := Request.Cookies.Cookie['session_id',Request.Host];
  if cookie = nil then
  begin
    // NOTE: Terribly insecure way to generate session IDs.  Do not immitate for
    //       anything in the real world.
    SessionID := Random(High(Integer)).ToString;
    cookie := Response.Cookies.Add;
    cookie.Domain := Request.Host;
    cookie.CookieName := 'session_id';
    cookie.Value := SessionID;
  end else
    SessionID := cookie.Value;
end;

initialization
  Randomize;

end.
