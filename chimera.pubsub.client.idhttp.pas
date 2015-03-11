// *****************************************************************************
//
// chimera.pubsub.client.idhttp;
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

unit chimera.pubsub.client.idhttp;

interface

uses System.SysUtils, System.Classes, IdHTTP, chimera.json,
  System.Generics.Collections;

type
  TMessageEvent = procedure(Sender : TObject; const Msg : IJSONObject) of object;
  TPubSubHTTPClient = class(TComponent)
  private
    FThreads : TDictionary<string, TThread>;
    FChannels: TStrings;
    FOnMessage: TMessageEvent;
    FPort: integer;
    FHost: string;
    FRootPath: string;
    FSynchronize: boolean;
    procedure SetChannels(const Value: TStrings);
  protected
    procedure DoMessage(const msg : IJSONObject); virtual;
    procedure DoMessages(const ary : IJSONArray); virtual;
  public
    procedure Subscribe(const Channel : string);
    procedure Unsubscribe(const Channel : string);

    procedure Publish(const Channel : string; const Msg : IJSONObject);

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Host : string read FHost write FHost;
    property Port : integer read FPort write FPort;
    property RootPath : string read FRootPath write FRootPath;
    property Channels : TStrings read FChannels write SetChannels;
    property OnMessage : TMessageEvent read FOnMessage write FOnMessage;
    property Syncronize : boolean read FSynchronize write FSynchronize default true;
  end;

procedure Register;

implementation

uses IdSSLOpenSSL, IdCookieManager;

procedure Register;
begin
  RegisterComponents('PubSub',[TPubSubHTTPClient]);
end;

{ TPubSubHTTPClient }

constructor TPubSubHTTPClient.Create(AOwner: TComponent);
begin
  inherited;
  FThreads := TDictionary<string, TThread>.Create;
  FChannels := TStringList.Create;
  FRootPath := '';
  FSynchronize := true;
end;

destructor TPubSubHTTPClient.Destroy;
var
  p: TPair<string, TThread>;
begin
  FChannels.Free;
  for p in FThreads do
  begin
    p.Value.Terminate;
  end;
  FThreads.Free;
  inherited;
end;

procedure TPubSubHTTPClient.DoMessage(const msg: IJSONObject);
begin
  if Assigned(FOnMessage) then
    FOnMessage(Self, msg);
end;

procedure TPubSubHTTPClient.DoMessages(const ary: IJSONArray);
var
  i: Integer;
begin
  for i := 0 to ary.Count-1 do
  begin
    DoMessage(ary.Objects[i]);
  end;
end;

procedure TPubSubHTTPClient.Publish(const Channel: string;
  const Msg: IJSONObject);
begin
  TThread.CreateAnonymousThread(
    procedure
    var
      http : TIdHTTP;
      sHost : string;
      ssPost : TStringStream;
    begin
      http := TIdHTTP.Create(nil);
      try
        if FHost.ToLower.StartsWith('https://') or (FPort = 443) then
          http.IOHandler := TIdSSLIOHandlerSocketOpenSSL.Create(http);
        http.AllowCookies := True;
        http.HandleRedirects := True;
        http.CookieManager := TIdCookieManager.Create(http);
        if FPort > 0 then
          sHost := FHost+':'+FPort.ToString+RootPath
        else
          sHost := FHost+RootPath;

        if not Channel.StartsWith('/') then
          sHost := sHost+'/';

        ssPost := TStringStream.Create(UTF8String(msg.AsJSON),TEncoding.UTF8);
        try
          http.Request.ContentType := 'application/json';
          http.Post(sHost+Channel, ssPost);
        finally
          ssPost.Free;
        end;
      finally
        http.Free;
      end;
    end
  ).Start;
end;

procedure TPubSubHTTPClient.SetChannels(const Value: TStrings);
begin
  FChannels.Assign(Value);
end;

type
  TThreadHack = class(TThread);

procedure TPubSubHTTPClient.Subscribe(const Channel: string);
var
  thread : TThread;
begin
  TMonitor.Enter(FThreads);
  try
    thread := TThread.CreateAnonymousThread(
      procedure
      var
        http : TIdHTTP;
        sHost : string;
        ssOut : TStringStream;
        jsa : IJSONArray;
      begin
        http := TIdHTTP.Create(nil);
        try
          if FHost.ToLower.StartsWith('https://') or (FPort = 443) then
            http.IOHandler := TIdSSLIOHandlerSocketOpenSSL.Create(http);
          http.AllowCookies := True;
          http.HandleRedirects := True;
          http.CookieManager := TIdCookieManager.Create(http);
          if FPort > 0 then
            sHost := FHost+':'+FPort.ToString+FRootPath
          else
            sHost := FHost+FRootPath;

          if not Channel.StartsWith('/') then
            sHost := sHost+'/';

          while not TThreadHack(TThread.CurrentThread).Terminated do
          begin
            ssOut := TStringStream.Create;
            try
              http.Get(sHost+Channel,ssOut);
              if ssOut.DataString <> '' then
              begin
                jsa := JSONArray(ssOut.DataString);
                if FSynchronize then
                begin
                  TThread.Synchronize(TThread.CurrentThread,
                    procedure
                    begin
                      DoMessages(jsa);
                    end
                  );
                end else
                  DoMessages(jsa);
              end;

            finally
              ssOut.Free;
            end;
          end;
        finally
          http.Free;
        end;
      end
    );
    FThreads.Add(Channel, thread);
    thread.Start;
  finally
    TMonitor.Exit(FThreads);
  end;
end;

procedure TPubSubHTTPClient.Unsubscribe(const Channel: string);
var
  thread : TThread;
begin
  TMonitor.Enter(FThreads);
  try
    if FThreads.TryGetValue(Channel, thread) then
    begin
      thread.Terminate;
      FThreads.ExtractPair(Channel);
    end;
  finally
    TMonitor.Exit(FThreads);
  end;
end;

end.
