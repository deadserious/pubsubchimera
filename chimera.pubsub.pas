// *****************************************************************************
//
// chimera.pubsub;
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

unit chimera.pubsub;

interface

uses System.SysUtils, System.Classes, System.Generics.Collections,
  System.SyncObjs;

type
  TMessageHandler<T> = reference to procedure(const Msg : T);

  IChannel<T> = interface(IInterface)
      function GetName : string;

      procedure Subscribe(Handler : TMessageHandler<T>; const ID : string = '');
      procedure Unsubscribe(Handler : TMessageHandler<T>; const ID : string = '');
      procedure Publish(const Msg : T; const ID : string = '');
      procedure BeginContext(const Context : string; const ID : string = ''); overload;
      procedure BeginContext(const Context : string; const Prefill : TArray<T>; const ID : string = ''); overload;
      function BeginAndGetContext(const Context : string; const ID : string = '') : TQueue<T>; overload;
      function BeginAndGetContext(const Context : string; const Prefill : TArray<T>; const ID : string = '') : TQueue<T>; overload;
      function EndContext(const Context : string) : TArray<T>;
      function WaitOnContext(const Context : string; Timeout : integer; const ID : string = '') : TArray<T>;
      //procedure LoadContext(const Context : String; const Data : TArray<T>; const ID : string = ''); overload;
      //procedure LoadContext(const Context : String; const Data : T; const ID : string = ''); overload;

      property Name : string read GetName;
  end;

  TCreateChannelHandler<T> = reference to function(const Channel : string) : IChannel<T>;
  TContextHandler<T> = reference to procedure(const channel : IChannel<T>; const Context : String; Queue : TQueue<T>);
  TDataHandler<T> = reference to procedure(const channel : IChannel<T>; const Context : string; Data : T );

  TPubSub<T> = class(TObject)
  strict private type
    TChannel<T> = class(TInterfacedObject, IChannel<T>)
    strict private type
      TDataContext<T> = class(TQueue<T>)
      private
        FEvent : TEvent;
        function GetEvent : TEvent;
        function GetCount : integer;
      protected
      public
        constructor Create;
        destructor Destroy; override;
        property Event : TEvent read GetEvent;
      end;
    private
      FName : string;
      FOwner : TPubSub<T>;
      FSubscriptions : TList<TMessageHandler<T>>;
      FContexts : TDictionary<string, TDataContext<T>>;
    public
      constructor Create(Owner : TPubSub<T>; const Name : String);
      destructor Destroy; override;
      function GetName : string;
      procedure Subscribe(Handler : TMessageHandler<T>; const ID : string = '');
      procedure Unsubscribe(Handler : TMessageHandler<T>; const ID : string = '');
      procedure Publish(const Msg : T; const ID : string = '');
      procedure BeginContext(const Context : string; const ID : string = ''); overload;
      procedure BeginContext(const Context : string; const Prefill : TArray<T>; const ID : string = ''); overload;
      function BeginAndGetContext(const Context : string; const ID : string = '') : TQueue<T>; overload;
      function BeginAndGetContext(const Context : string; const Prefill : TArray<T>; const ID : string = '') : TQueue<T>; overload;
      function EndContext(const Context : string) : TArray<T>;
      function WaitOnContext(const Context : string; Timeout : integer = -1; const ID : string = '') : TArray<T>;
      //procedure LoadContext(const Context : String; const Data : TArray<T>; const ID : string = ''); overload;
      //procedure LoadContext(const Context : String; const Data : T; const ID : string = ''); overload;

      property Name : string read GetName;
    end;
  strict private
    FChannels : TDictionary<string,IChannel<T>>;
    FOnCreateChannel: TCreateChannelHandler<T>;
    FOnReloadContext: TContextHandler<T>;
    FOnClearMessage: TDataHandler<T>;
    FOnStoreMessage: TDataHandler<T>;

    function Lookup(const Channel : string) : IChannel<T>;

  private
    function DoCreateChannel(const Channel : string) : IChannel<T>;
    procedure DoReloadContext(const channel : IChannel<T>; const Context : String; Queue : TQueue<T>);
    procedure DoStoreMessage(const channel : IChannel<T>; const Context : string; Data : T );
    procedure DoClearMessage(const channel : IChannel<T>; const Context : string; Data : T );
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Subscribe(const Channel : string; Handler : TMessageHandler<T>; const ID : string = ''); virtual;
    procedure Unsubscribe(const Channel : string; Handler : TMessageHandler<T>; const ID : string = ''); virtual;
    function ListenAndWait(const Channel : string; Timeout : integer = -1; const ID : string = '') : T; overload;  virtual;
    function ListenAndWait(const Channel : string; const Context : string; Timeout : integer = -1; const ID : string = '') : TArray<T>; overload;  virtual;
    procedure BeginContext(const Channel : string; const Context : string); virtual;
    function EndContext(const Channel : string; const Context : string) : TArray<T>; virtual;
    procedure Publish(const Channel : string; const Msg : T; const ID : string = ''); virtual;

    property OnCreateChannel : TCreateChannelHandler<T> read FOnCreateChannel write FOnCreateChannel;
    property OnReloadContext : TContextHandler<T> read FOnReloadContext write FOnReloadContext;
    property OnStoreMessage : TDataHandler<T> read FOnStoreMessage write FOnStoreMessage;
    property OnClearMessage : TDataHandler<T> read FOnClearMessage write FOnClearMessage;
  end;

implementation

{ TPubSub<T> }

procedure TPubSub<T>.BeginContext(const Channel, Context: string);
var
  chnl : IChannel<T>;
begin
  chnl := Lookup(Channel);
  chnl.BeginAndGetContext(Context);
end;

constructor TPubSub<T>.Create;
begin
  inherited Create;
  FChannels := TDictionary<string, IChannel<T>>.Create;
  FOnCreateChannel :=
    function(const Name : string) : IChannel<T>
    begin
      Result := TChannel<T>.Create(Self, Name);
    end;
end;

destructor TPubSub<T>.Destroy;
var
  c: TPair<string, IChannel<T>>;
begin
  TMonitor.Enter(FChannels);
  try
    FChannels.Clear;
  finally
    TMonitor.Exit(FChannels);
  end;
  FChannels.Free;
  inherited Destroy;
end;

procedure TPubSub<T>.DoClearMessage(const channel: IChannel<T>;
  const Context: string; Data: T);
begin
  if Assigned(FOnClearMessage) then
    FOnClearMessage(channel, Context, Data);
end;

function TPubSub<T>.DoCreateChannel(const Channel: string): IChannel<T>;
begin
  if Assigned(FOnCreateChannel) then
    Result := FOnCreateChannel(channel)
  else
    Result := nil;
end;

procedure TPubSub<T>.DoReloadContext(const channel : IChannel<T>; const Context : String; Queue : TQueue<T>);
begin
  if Assigned(FOnReloadContext) then
    FOnReloadContext(channel, Context, Queue);
end;

procedure TPubSub<T>.DoStoreMessage(const channel: IChannel<T>;
  const Context: string; Data: T);
begin
  if Assigned(FOnStoreMessage) then
    FOnStoreMessage(Channel, Context, Data);
end;

function TPubSub<T>.EndContext(const Channel, Context: string): TArray<T>;
begin
  Result := Lookup(Channel).EndContext(Context);
end;

function TPubSub<T>.ListenAndWait(const Channel: string; Timeout: integer = -1; const ID : string = ''): T;
var
  event : TEvent;
  msgResult : T;
begin
  event := TEvent.Create;
  try
    Lookup(Channel).Subscribe(
      procedure(const Msg : T)
      begin
        MsgResult := Msg;
        event.SetEvent;
      end
    , ID);
    if event.WaitFor(Timeout) = TWaitResult.wrSignaled then
    begin
      result := msgResult;
    end else
      Result := T(nil);
  finally
    event.Free;
  end;
end;

function TPubSub<T>.ListenAndWait(const Channel, Context: string; Timeout: integer = -1; const ID : string = ''): TArray<T>;
begin
  Result := Lookup(Channel).WaitOnContext(Context, Timeout, ID);
end;

function TPubSub<T>.Lookup(const Channel: string): IChannel<T>;
begin
  TMonitor.Enter(FChannels);
  try
    if not FChannels.TryGetValue(Channel,Result) then
    begin
      Result := DoCreateChannel(Channel);
      FChannels.Add(Channel, Result);
    end;
  finally
    TMonitor.Exit(FChannels);
  end;
end;

procedure TPubSub<T>.Publish(const Channel: string; const Msg: T; const ID : string = '');
begin
  Lookup(Channel).Publish(Msg, ID);
end;

procedure TPubSub<T>.Subscribe(const Channel: string; Handler: TMessageHandler<T>; const ID : string = '');
begin
  Lookup(Channel).Subscribe(Handler, ID);
end;

procedure TPubSub<T>.Unsubscribe(const Channel: string; Handler: TMessageHandler<T>; const ID : string = '');
begin
  Lookup(Channel).Unsubscribe(Handler, ID);
end;

{ TPubSub<T>.TChannel<T> }

function TPubSub<T>.TChannel<T>.BeginAndGetContext(const Context: string; const Prefill : TArray<T>; const ID : string = '') : TQueue<T>;
var
  dc : TDataContext<T>;
begin
  TMonitor.Enter(FContexts);
  try
    if not FContexts.TryGetValue(Context, dc) then
    begin
      dc := TDataContext<T>.Create;
      FContexts.Add(Context, dc);
      FOwner.DoReloadContext(Self, Context, dc);
    end;
  finally
    TMonitor.Exit(FContexts);
  end;
  Result := dc;
end;

function TPubSub<T>.TChannel<T>.BeginAndGetContext(const Context: string; const ID : string = '') : TQueue<T>;
var
  ary : TArray<T>;
begin
  SetLength(ary,0);
  Result := BeginAndGetContext(Context, ary, ID);
end;

procedure TPubSub<T>.TChannel<T>.BeginContext(const Context, ID: string);
begin
  BeginAndGetContext(Context, ID);
end;

procedure TPubSub<T>.TChannel<T>.BeginContext(const Context: string;
  const Prefill: TArray<T>; const ID: string);
begin
  BeginAndGetContext(Context, Prefill, ID);
end;

constructor TPubSub<T>.TChannel<T>.Create(Owner : TPubSub<T>; const Name : String);
begin
  inherited Create;
  FName := Name;
  FOwner := Owner;
  FSubscriptions := TList<TMessageHandler<T>>.Create;
  FContexts := TDictionary<string, TDataContext<T>>.Create;
end;

destructor TPubSub<T>.TChannel<T>.Destroy;
begin
  FSubscriptions.Free;
  FContexts.Free;
  inherited;
end;

function TPubSub<T>.TChannel<T>.EndContext(const Context: string) : TArray<T>;
var
  q : TDataContext<T>;
  i: Integer;
begin
  SetLength(Result,0);
  TMonitor.Enter(FContexts);
  try
    if FContexts.TryGetValue(Context,q) then
    begin
      setLength(Result,q.Count);
      i := 0;
      while q.Count > 0 do
      begin
        Result[i] := q.Dequeue;
        inc(i);
      end;
      FContexts.Remove(Context);
    end;
  finally
    TMonitor.Exit(FContexts);
  end;
end;

function TPubSub<T>.TChannel<T>.GetName: string;
begin
  Result := FName;
end;

{procedure TPubSub<T>.TChannel<T>.LoadContext(const Context: String;
  const Data: TArray<T>; const ID : string = '');
var
  cxt : TDataContext<T>;
  p : TPair<string, TDataContext<T>>;
  i : integer;
begin
  TMonitor.Enter(Self);
  try
    if not FContexts.TryGetValue(Context,cxt) then
      BeginContext(Context, ID);

    for p in FContexts do
    begin
      for i := 0 to length(Data) do
        p.Value.Enqueue(Data[i]);
      p.Value.Event.SetEvent;
    end;
  finally
    TMonitor.Exit(Self);
  end;

end;

procedure TPubSub<T>.TChannel<T>.LoadContext(const Context: String;
  const Data: T; const ID : string = '');
var
  ary : TArray<T>;
begin
  SetLength(ary,1);
  ary[0] := Data;
  LoadContext(Context,ary,ID);
end;}

procedure TPubSub<T>.TChannel<T>.Publish(const Msg: T; const ID : string = '');
var
  h: TMessageHandler<T>;
  p : TPair<string, TDataContext<T>>;
begin
  TMonitor.Enter(Self);
  try
    FOwner.DoStoreMessage(Self,'',Msg);
    for h in FSubscriptions do
    begin
      h(Msg);
    end;
    FOwner.DoClearMessage(Self,'',Msg);
    for p in FContexts do
    begin
      p.Value.Enqueue(Msg);
      if p.Key <> '' then
        FOwner.DoStoreMessage(Self,p.Key,Msg);
      p.Value.Event.SetEvent;
    end;
  finally
    TMonitor.Exit(Self);
  end;
end;

procedure TPubSub<T>.TChannel<T>.Subscribe(Handler: TMessageHandler<T>; const ID : string = '');
begin
  TMonitor.Enter(Self);
  try
    FSubscriptions.Add(Handler);
  finally
    TMonitor.Exit(Self);
  end;
end;

procedure TPubSub<T>.TChannel<T>.Unsubscribe(Handler: TMessageHandler<T>; const ID : string = '');
begin
  TMonitor.Enter(Self);
  try
    FSubscriptions.Remove(Handler);
  finally
    TMonitor.Exit(Self);
  end;
end;

function TPubSub<T>.TChannel<T>.WaitOnContext(const Context: string; Timeout: integer = -1; const ID : string = ''): TArray<T>;
var
  q : TDataContext<T>;
  cnt : Integer;
  i: Integer;
begin
  q := TDataContext<T>(BeginAndGetContext(Context));
  TMonitor.Enter(q);
  try
    cnt := q.Count;
  finally
    TMonitor.Exit(q);
  end;
  if cnt = 0 then
  begin
    q.Event.ResetEvent;
    q.Event.WaitFor(Timeout);
  end;
  TMonitor.Enter(q);
  try
    i := 0;
    setlength(Result, q.Count);
    while q.Count > 0 do
    begin
      Result[i] := q.Dequeue;
      FOwner.DoClearMessage(Self, Context, Result[i]);
      inc(i);
    end;
  finally
    TMonitor.Exit(q);
  end;
end;

{ TPubSub<T>.TChannel<T>.TDataContext<T> }

constructor TPubSub<T>.TChannel<T>.TDataContext<T>.Create;
begin
  inherited Create;
  FEvent := TEvent.Create;
end;

destructor TPubSub<T>.TChannel<T>.TDataContext<T>.Destroy;
begin
  FEvent.Free;
  inherited;
end;

function TPubSub<T>.TChannel<T>.TDataContext<T>.GetCount: integer;
begin
  Result := inherited Count;
end;

function TPubSub<T>.TChannel<T>.TDataContext<T>.GetEvent: TEvent;
begin
  result := FEvent;
end;


end.
