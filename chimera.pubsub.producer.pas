unit chimera.pubsub.producer;

interface

uses
  System.SysUtils, System.Classes, Web.HTTPApp;

type
  TSessionEvent = procedure(Sender : TObject; var SessionID : string) of object;
  TPubSubAuthEvent = procedure(Sender : TObject; const channel : string; var Permitted : boolean) of object;
  TParseEvent = procedure(Sender : TObject; Request : TWebRequest; var Value : string) of object;
  TPubSubProducer = class(TCustomContentProducer)
  private
    FOnSession: TSessionEvent;
    FOnCanSubscribe: TPubSubAuthEvent;
    FOnCanPublish: TPubSubAuthEvent;
    FOnParseMessage: TParseEvent;
    FOnParseChannel: TParseEvent;
    FTimeout: integer;
  protected
    function ParseChannel : string; virtual;
    function ParseMessage : string; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    function Content: string; override;
  published
    property Timeout : integer read FTimeout write FTimeout default -1;
    property OnSession : TSessionEvent read FOnSession write FOnSession;
    property OnCanSubscribe : TPubSubAuthEvent read FOnCanSubscribe write FOnCanSubscribe;
    property OnCanPublish : TPubSubAuthEvent read FOnCanPublish write FOnCanPublish;
    property OnParseChannel : TParseEvent read FOnParseChannel write FOnParseChannel;
    property OnParseMessage : TParseEvent read FOnParseMessage write FOnParseMessage;
  end;

procedure Register;

implementation

uses chimera.pubsub;

procedure Register;
begin
  RegisterComponents('PubSub',[TPubSubProducer]);
end;

{ TPubSubProducer }

function TPubSubProducer.Content: string;
var
  sSession : string;
  ary: TArray<string>;
  i: Integer;
begin
      case Dispatcher.Request.MethodType of
    TMethodType.mtPost,
    TMethodType.mtPut:
      TPubSub<string>.Publish(ParseChannel, ParseMessage);
    TMethodType.mtGet:
    begin
      sSession := '';
      if Assigned(FOnSession) then
      begin
        FOnSession(Self, sSession);
        ary := TPubSub<String>.ListenAndWait(ParseChannel, sSession, FTimeout);
        result := '[';
        for i := 0 to length(ary) do
        begin
          if i > 0 then
            result := result+',';
          result := result+'"'+ary[i].Replace('"','''',[rfReplaceAll]);
        end;
        result := result+']';
      end else
        result := '["'+TPubSub<string>.ListenAndWait(ParseChannel, FTimeout).Replace('"','''',[rfReplaceAll])+'"]';
    end;
  end;

end;

constructor TPubSubProducer.Create(AOwner: TComponent);
begin
  inherited;
  FTimeout := -1;
end;

function TPubSubProducer.ParseChannel: string;
begin
  Result := Dispatcher.Request.PathInfo;
  if Assigned(FOnParseChannel) then
    FOnParseChannel(Self, Dispatcher.Request, Result);
end;

function TPubSubProducer.ParseMessage: string;
begin
  Result := Dispatcher.Request.Content;
  if Assigned(FOnParseMessage) then
    FOnParseMessage(Self, Dispatcher.Request, Result);
end;

end.
