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
  IMessage = interface
    function GetName : string;
    procedure SetName(const Value : string);
    function GetContentType : string;
    procedure SetContentType(const Value : string);
    function GetAsString : string;
    procedure SetAsString(const Value : string);
    function GetAsStream : TStream;
    procedure SetAsStream(const Value : TStream);

    property AsString : string read GetAsString write SetAsString;
    property AsStream : TStream read GetAsStream write SetAsStream;
    property Name : string read GetName write SetName;
    property ContentType : string read GetContentType write SetContentType;

    function Initialize(Name : string; Content : string; ContentType : string = '') : IMessage; overload;
    function Initialize(Name : string; Content : TStream; ContentType : string = '') : IMessage; overload;
  end;

  TMessageHandler<T> = reference to procedure(const Msg : T);

  TPubSub<T> = class
  strict private type
    TMessages<T> = class(TObject)
    strict private type
      TEventQueue<T> = class(TQueue<T>)
      public
        Event : TEvent;
        constructor Create;
        destructor Destroy; override;
      end;
    private
      FSubscriptions : TList<TMessageHandler<T>>;
      FQueues : TDictionary<string, TEventQueue<T>>;
    public
      constructor Create;
      destructor Destroy; override;
      procedure Subscribe(Handler : TMessageHandler<T>);
      procedure Unsubscribe(Handler : TMessageHandler<T>);
      procedure Publish(const Msg : T);
      function BeginQueue(const Queue : string) : TEventQueue<T>;
      function EndQueue(const Queue : string) : TArray<T>;
      function WaitOnQueue(const Queue : string; Timeout : integer) : TArray<T>;
    end;
  strict private class var
    FChannels : TDictionary<string,TMessages<T>>;
  strict private
    class function Lookup(const Channel : string) : TMessages<T>;
  public
    class constructor Create;
    class destructor Destroy;
    class procedure Subscribe(const Channel : string; Handler : TMessageHandler<T>);
    class procedure Unsubscribe(const Channel : string; Handler : TMessageHandler<T>);
    class function ListenAndWait(const Channel : string; Timeout : integer = -1) : T; overload;
    class function ListenAndWait(const Channel : string; const Queue : string; Timeout : integer = -1) : TArray<T>; overload;
    class procedure BeginQueue(const Channel : string; const Queue : string);
    class function EndQueue(const Channel : string; const Queue : string) : TArray<T>;
    class procedure Publish(const Channel : string; const Msg : T);
  end;

  TMessageHandler = TMessageHandler<IMessage>;
  TPubSub = class(TPubSub<IMessage>)
  public
    class function NewMessage : IMessage;
  end;

implementation

type
  TMessage = class(TInterfacedObject, IMessage)
  private
    FData : TStream;
    FContentType: string;
    FName: string;
    function GetName : string;
    procedure SetName(const Value : string);
    function GetContentType : string;
    procedure SetContentType(const Value : string);
    function GetAsString : string;
    procedure SetAsString(const Value : string);
    function GetAsStream : TStream;
    procedure SetAsStream(const Value : TStream);
  public
    constructor Create;
    destructor Destroy; override;

    property AsString : string read GetAsString write SetAsString;
    property AsStream : TStream read GetAsStream write SetAsStream;
    property Name : string read GetName write SetName;
    property ContentType : string read GetContentType write SetContentType;

    function Initialize(Name : string; Content : string; ContentType : string = '') : IMessage; overload;
    function Initialize(Name : string; Content : TStream; ContentType : string = '') : IMessage; overload;
  end;

{ TPubSub }

class function TPubSub.NewMessage: IMessage;
begin
  Result := TMessage.Create;
end;

{ TMessage }

constructor TMessage.Create;
begin
  inherited Create;
  FData := TStringStream.Create;
end;

destructor TMessage.Destroy;
begin
  FData.Free;
  inherited;
end;

function TMessage.GetAsStream: TStream;
begin
  Result := FData;
end;

function TMessage.GetAsString: string;
begin
  Result := TStringStream(FData).DataString;
end;

function TMessage.GetContentType: string;
begin
  Result := FContentType;
end;

function TMessage.GetName: string;
begin
  Result := FName;
end;

function TMessage.Initialize(Name: string; Content: TStream;
  ContentType: string): IMessage;
begin
  FName := Name;
  FContentType := ContentType;
  FData.CopyFrom(Content, Content.Size-Content.Position);
  Result := Self;
end;

function TMessage.Initialize(Name, Content, ContentType: string): IMessage;
begin
  FName := Name;
  FContentType := ContentType;
  TStringStream(FData).WriteString(Content);
  Result := Self;
end;

procedure TMessage.SetAsStream(const Value: TStream);
begin
  FData.Size := 0;
  Value.Position := 0;
  FData.CopyFrom(Value,Value.Size);
end;

procedure TMessage.SetAsString(const Value: string);
begin
  FData.Size := 0;
  TStringStream(FData).WriteString(Value);
end;

procedure TMessage.SetContentType(const Value: string);
begin
  FContentType := Value;
end;

procedure TMessage.SetName(const Value: string);
begin
  FName := Value;
end;

{ TPubSub<T> }

class procedure TPubSub<T>.BeginQueue(const Channel, Queue: string);
begin
  Lookup(Channel).BeginQueue(Queue);
end;

class constructor TPubSub<T>.Create;
begin
  FChannels := TDictionary<string, TMessages<T>>.Create;
end;

class destructor TPubSub<T>.Destroy;
var
  c: TPair<string, TMessages<T>>;
begin
  TMonitor.Enter(FChannels);
  try
    for c in FChannels do
    begin
      c.Value.Free;
    end;
    FChannels.Clear;
  finally
    TMonitor.Exit(FChannels);
  end;
  FChannels.Free;
end;

class function TPubSub<T>.EndQueue(const Channel, Queue: string): TArray<T>;
begin
  Result := Lookup(Channel).EndQueue(Queue);
end;

class function TPubSub<T>.ListenAndWait(const Channel: string;
  Timeout: integer): T;
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
    );
    if event.WaitFor(Timeout) = TWaitResult.wrSignaled then
    begin
      result := msgResult;
    end else
      Result := T(nil);
  finally
    event.Free;
  end;
end;

class function TPubSub<T>.ListenAndWait(const Channel, Queue: string;
  Timeout: integer): TArray<T>;
begin
  Result := Lookup(Channel).WaitOnQueue(Queue, Timeout);
end;

class function TPubSub<T>.Lookup(const Channel: string): TMessages<T>;
begin
  TMonitor.Enter(FChannels);
  try
    if not FChannels.TryGetValue(Channel,Result) then
    begin
      Result := TMessages<T>.Create;
      FChannels.Add(Channel, Result);
    end;
  finally
    TMonitor.Exit(FChannels);
  end;
end;

class procedure TPubSub<T>.Publish(const Channel: string; const Msg: T);
begin
  Lookup(Channel).Publish(Msg);
end;

class procedure TPubSub<T>.Subscribe(const Channel: string;
  Handler: TMessageHandler<T>);
begin
  Lookup(Channel).Subscribe(Handler);
end;

class procedure TPubSub<T>.Unsubscribe(const Channel: string;
  Handler: TMessageHandler<T>);
begin
  Lookup(Channel).Unsubscribe(Handler);
end;

{ TPubSub<T>.TMessages<T> }

function TPubSub<T>.TMessages<T>.BeginQueue(const Queue: string) : TEventQueue<T>;
begin
  TMonitor.Enter(FQueues);
  try
    if not FQueues.TryGetValue(Queue, Result) then
    begin
      Result := TEventQueue<T>.Create;
      FQueues.Add(Queue, Result);
    end;
  finally
    TMonitor.Exit(FQueues);
  end;
end;

constructor TPubSub<T>.TMessages<T>.Create;
begin
  FSubscriptions := TList<TMessageHandler<T>>.Create;
  FQueues := TDictionary<string, TEventQueue<T>>.Create;
end;

destructor TPubSub<T>.TMessages<T>.Destroy;
begin
  FSubscriptions.Free;
  FQueues.Free;
  inherited;
end;

function TPubSub<T>.TMessages<T>.EndQueue(const Queue: string) : TArray<T>;
var
  q : TEventQueue<T>;
  i: Integer;
begin
  SetLength(Result,0);
  TMonitor.Enter(FQueues);
  try
    if FQueues.TryGetValue(Queue,q) then
    begin
      setLength(Result,q.Count);
      i := 0;
      while q.Count > 0 do
      begin
        Result[i] := q.Dequeue;
        inc(i);
      end;
      q.Free;
      FQueues.Remove(Queue);
    end;
  finally
    TMonitor.Exit(FQueues);
  end;
end;

procedure TPubSub<T>.TMessages<T>.Publish(const Msg: T);
var
  h: TMessageHandler<T>;
  p : TPair<string, TEventQueue<T>>;
begin
  TMonitor.Enter(Self);
  try
    for h in FSubscriptions do
    begin
      h(Msg);
    end;
    for p in FQueues do
    begin
      p.Value.Enqueue(Msg);
      p.Value.Event.SetEvent;
    end;
  finally
    TMonitor.Exit(Self);
  end;
end;

procedure TPubSub<T>.TMessages<T>.Subscribe(Handler: TMessageHandler<T>);
begin
  TMonitor.Enter(Self);
  try
    FSubscriptions.Add(Handler);
  finally
    TMonitor.Exit(Self);
  end;
end;

procedure TPubSub<T>.TMessages<T>.Unsubscribe(Handler: TMessageHandler<T>);
begin
  TMonitor.Enter(Self);
  try
    FSubscriptions.Remove(Handler);
  finally
    TMonitor.Exit(Self);
  end;
end;

function TPubSub<T>.TMessages<T>.WaitOnQueue(const Queue: string;
  Timeout: integer): TArray<T>;
var
  q : TEventQueue<T>;
  cnt : Integer;
  i: Integer;
begin
  q := BeginQueue(Queue);
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
      inc(i);
    end;
  finally
    TMonitor.Exit(q);
  end;
end;

{ TPubSub<T>.TMessages<T>.TEventQueue<T> }

constructor TPubSub<T>.TMessages<T>.TEventQueue<T>.Create;
begin
  inherited Create;
  Event := TEvent.Create;
end;

destructor TPubSub<T>.TMessages<T>.TEventQueue<T>.Destroy;
begin
  Event.Free;
  inherited;
end;

end.
