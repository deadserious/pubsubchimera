// *****************************************************************************
//
// chimera.pubsub.server.idhttp;
//
// PubSub Chimera project for Delphi
//
// Copyright (c) 2014 by Sivv Corp, All Rights Reserved
//
// Information about this product can be found at
// http://arcana.sivv.com/chimera
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
// *****************************************************************************

unit chimera.pubsub.server.idhttp;

interface

uses System.SysUtils, System.Classes, chimera.json, IdCustomHTTPServer, IdContext,
  chimera.pubsub.common, chimera.pubsub;

type
  TIDEvent = procedure(Sender : TObject; Request : TIdHTTPRequestInfo; Response : TIdHTTPResponseInfo; var ID : string) of object;
  TPubSubAuthEvent = procedure(Sender : TObject; Request : TIdHTTPRequestInfo; const channel : string; var Permitted : boolean) of object;
  TParseDataEvent = procedure(Sender : TObject; Request : TIdHTTPRequestInfo; var Value : IJSONObject) of object;
  TParseChannelEvent = procedure(Sender : TObject; Request : TIdHTTPRequestInfo; var Value : string) of object;

  TPubSubHTTPServer = class(TIdCustomHTTPServer)
  private
    FPubSub : TPubSub<IJSONObject>;
    FOnSession: TIDEvent;
    FOnCanSubscribe: TPubSubAuthEvent;
    FOnParseMessage: TParseDataEvent;
    FTimeout: integer;
    FOnParseChannel: TParseChannelEvent;
    FOnCanPublish: TPubSubAuthEvent;
    FOnGetID: TIDEvent;
    function DoGetID(Request : TIdHTTPRequestInfo; Response : TIdHTTPResponseInfo) : string;
  protected
    function ParseChannel(Request : TIdHTTPRequestInfo) : string; virtual;
    function ParseMessage(Request : TIdHTTPRequestInfo) : IJSONObject; virtual;
    function CanPublish(Request : TIdHTTPRequestInfo) : boolean;
    function CanSubscribe(Request : TIdHTTPRequestInfo) : boolean;

    procedure DoCommandGet(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
      override;
  public
    procedure InitComponent; override;
    destructor Destroy; override;
    function PubSub : TPubSub<IJSONObject>;
  published
    property Timeout : integer read FTimeout write FTimeout default -1;
    property OnSession : TIDEvent read FOnSession write FOnSession;
    property OnGetID : TIDEvent read FOnGetID write FOnGetID;
    property OnCanSubscribe : TPubSubAuthEvent read FOnCanSubscribe write FOnCanSubscribe;
    property OnCanPublish : TPubSubAuthEvent read FOnCanPublish write FOnCanPublish;
    property OnParseChannel : TParseChannelEvent read FOnParseChannel write FOnParseChannel;
    property OnParseMessage : TParseDataEvent read FOnParseMessage write FOnParseMessage;
    property OnCommandGet;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('PubSub',[TPubSubHTTPServer]);
end;

{ TPubSubHTTPServer }

function TPubSubHTTPServer.CanPublish(Request : TIdHTTPRequestInfo): boolean;
begin
  Result := True;
  if Assigned(FOnCanPublish) then
    FOnCanPublish(Self, Request, ParseChannel(Request), Result);
end;

function TPubSubHTTPServer.CanSubscribe(Request : TIdHTTPRequestInfo): boolean;
begin
  Result := True;
  if Assigned(FOnCanSubscribe) then
    FOnCanSubscribe(Self, Request, ParseChannel(Request), Result);
end;

destructor TPubSubHTTPServer.Destroy;
begin
  FPubSub.Free;
  inherited;
end;

procedure TPubSubHTTPServer.DoCommandGet(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
var
  sSession : string;
  ary: TArray<IJSONObject>;
  i: Integer;
  jsa : IJSONArray;
begin
  inherited;
  if (  (AResponseInfo.ContentStream = nil) or
        (AResponseInfo.ContentStream.Size = 0)
     ) and
     (AResponseInfo.ContentType = '') and
     (not ARequestInfo.Document.Contains('.')) then
  begin
    if ARequestInfo.CommandType in [THTTPCommandType.hcPOST, THTTPCommandType.hcPUT] then
    begin
      if CanPublish(ARequestInfo) then
        FPubSub.Publish(ParseChannel(ARequestInfo), ParseMessage(ARequestInfo), DoGetID(ARequestInfo, AResponseInfo))
      else
        raise EPubSubSecurityException.Create(NOT_ALLOWED);
    end else
    begin
      if CanSubscribe(ARequestInfo) then
      begin
        sSession := '';
        jsa := JSONArray;
        if Assigned(FOnSession) then
        begin
          // If a session is provided, then use queueing mechanism
          FOnSession(Self, ARequestInfo, AResponseInfo, sSession);
          ary := FPubSub.ListenAndWait(ParseChannel(ARequestInfo), sSession, FTimeout, DoGetID(ARequestInfo, AResponseInfo));
          for i := 0 to length(ary)-1 do
          begin
            jsa.Add(ary[i]);
          end;
        end else
        begin
          // If no session provided, just wait for next message
          jsa.Add(FPubSub.ListenAndWait(ParseChannel(ARequestInfo), DoGetID(ARequestInfo, AResponseInfo), FTimeout));
        end;
      end else
        raise EPubSubSecurityException.Create(NOT_ALLOWED);
      AResponseInfo.ContentText := jsa.AsJSON;
      AResponseInfo.ContentType := 'application/json';
    end;
  end;
end;

function TPubSubHTTPServer.DoGetID(Request : TIdHTTPRequestInfo; Response : TIdHTTPREsponseInfo): string;
begin
  Result := '';
  if Assigned(FOnGetID) then
    FOnGetID(Self, Request, Response, Result);
end;

procedure TPubSubHTTPServer.InitComponent;
begin
  inherited;
  FTimeout := -1;
  FPubSub := TPubSub<IJSONObject>.Create;
end;

function TPubSubHTTPServer.ParseChannel(Request : TIdHTTPRequestInfo): string;
begin
  Result := Request.Document;
  if Assigned(FOnParseChannel) then
    FOnParseChannel(Self, Request, Result);
end;

function TPubSubHTTPServer.ParseMessage(Request : TIdHTTPRequestInfo): IJSONObject;
var
  sContent : UTF8String;
begin
  if Request.PostStream <> nil then
  begin
    SetLength(sContent, Request.PostStream.Size);
    Request.PostStream.Read(sContent[1],Request.PostStream.Size);
    Result := JSON(sContent);
  end else
    Result := JSON(Request.UnparsedParams);

  if Assigned(FOnParseMessage) then
    FOnParseMessage(Self, Request, Result);
end;

function TPubSubHTTPServer.PubSub: TPubSub<IJSONObject>;
begin
  if not Assigned(FPubSub) then
    FPubSub := TPubSub<IJSONObject>.Create;
  Result := FPubSub;
end;

end.
