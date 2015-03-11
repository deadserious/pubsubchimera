// *****************************************************************************
//
// chimera.pubsub.producer;
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

unit chimera.pubsub.producer;

interface

uses
  System.SysUtils, System.Classes, Web.HTTPApp, chimera.json, chimera.pubsub.common,
  chimera.pubsub;

type
  TIDEvent = procedure(Sender : TObject; Request : TWebRequest; Response : TWebResponse; var ID : string) of object;
  TPubSubAuthEvent = procedure(Sender : TObject; Request : TWebRequest; const channel : string; var Permitted : boolean) of object;
  TParseChannelEvent = procedure(Sender : TObject; Request : TWebRequest; var Value : string) of object;
  TParseDataEvent = procedure(Sender : TObject; Request : TWebRequest; var Value : IJSONObject) of object;
  TPubSubProducer = class(TCustomContentProducer)
  strict private
    class var FPubSub : TPubSub<IJSONObject>;
  private
    FOnSession: TIDEvent;
    FOnGetID : TIDEvent;
    FOnCanSubscribe: TPubSubAuthEvent;
    FOnCanPublish: TPubSubAuthEvent;
    FOnParseMessage: TParseDataEvent;
    FOnParseChannel: TParseChannelEvent;
    FTimeout: integer;
  protected
    function ParseChannel : string; virtual;
    function ParseMessage : IJSONObject; virtual;
    function CanPublish : boolean;
    function CanSubscribe : boolean;
    function DoGetID : string;
  public
    constructor Create(AOwner: TComponent); override;
    function Content: string; override;
    class function PubSub : TPubSub<IJSONObject>;
  published
    property Timeout : integer read FTimeout write FTimeout default -1;
    property OnSession : TIDEvent read FOnSession write FOnSession;
    property OnCanSubscribe : TPubSubAuthEvent read FOnCanSubscribe write FOnCanSubscribe;
    property OnCanPublish : TPubSubAuthEvent read FOnCanPublish write FOnCanPublish;
    property OnParseChannel : TParseChannelEvent read FOnParseChannel write FOnParseChannel;
    property OnParseMessage : TParseDataEvent read FOnParseMessage write FOnParseMessage;
    property OnGetID : TIDEvent read FOnGetID write FOnGetID;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('PubSub',[TPubSubProducer]);
end;

{ TPubSubProducer }

function TPubSubProducer.CanPublish: boolean;
begin
  Result := True;
  if Assigned(FOnCanPublish) then
    FOnCanPublish(Self, Dispatcher.Request, ParseChannel, Result);
end;

function TPubSubProducer.CanSubscribe: boolean;
begin
  Result := True;
  if Assigned(FOnCanSubscribe) then
    FOnCanSubscribe(Self, Dispatcher.Request, ParseChannel, Result);
end;

function TPubSubProducer.Content: string;
var
  sSession : string;
  ary: TArray<IJSONObject>;
  jsa : IJSONArray;
  i: Integer;
begin
  case Dispatcher.Request.MethodType of
    TMethodType.mtPost,
    TMethodType.mtPut:
      if CanPublish then
        PubSub.Publish(ParseChannel, ParseMessage, DoGetID)
      else
        raise EPubSubSecurityException.Create(NOT_ALLOWED);
    TMethodType.mtGet:
    begin
      if CanSubscribe then
      begin
        sSession := '';
        jsa := JSONArray;
        if Assigned(FOnSession) then
        begin
          // If a session is provided, then use queueing mechanism
          FOnSession(Self, Dispatcher.Request, Dispatcher.Response, sSession);
          ary := PubSub.ListenAndWait(ParseChannel, sSession, FTimeout, DoGetID);
          for i := 0 to length(ary)-1 do
          begin
            jsa.Add(ary[i]);
          end;
        end else
        begin
          // If no session provided, just wait for next message
          jsa.Add(PubSub.ListenAndWait(ParseChannel, FTimeout, DoGetID));
        end;
        Result := jsa.AsJSON;
        Dispatcher.Response.ContentType := 'application/json';
      end else
        raise EPubSubSecurityException.Create(NOT_ALLOWED);
    end;
  end;

end;

constructor TPubSubProducer.Create(AOwner: TComponent);
begin
  inherited;
  FTimeout := -1;
end;

function TPubSubProducer.DoGetID: string;
begin
  Result := '';
  if Assigned(FOnGetID) then
    FOnGetID(Self, Dispatcher.Request, Dispatcher.Response, Result);
end;

function TPubSubProducer.ParseChannel: string;
begin
  Result := Dispatcher.Request.PathInfo;
  if Assigned(FOnParseChannel) then
    FOnParseChannel(Self, Dispatcher.Request, Result);
end;

function TPubSubProducer.ParseMessage : IJSONObject;
begin
  Result := JSON(Dispatcher.Request.Content);
  if Assigned(FOnParseMessage) then
    FOnParseMessage(Self, Dispatcher.Request, Result);
end;

class function TPubSubProducer.PubSub: TPubSub<IJSONObject>;
begin
  if not Assigned(FPubSub) then
    FPubSub := TPubSub<IJSONObject>.Create;
  Result := FPubSub;
end;

end.
