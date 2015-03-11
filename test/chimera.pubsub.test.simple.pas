// *****************************************************************************
//
// chimera.pubsub.test.simple;
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

unit chimera.pubsub.test.simple;

interface

uses System.SysUtils, System.Classes, chimera.pubsub;

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

  TMessageHandler = TMessageHandler<IMessage>;
  TPubSub = class(TPubSub<IMessage>)
  public
    class function NewMessage : IMessage;
  end;


procedure TestPubSub;
procedure TestListenWait;
procedure TestContext;

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

procedure TestPubSub;
var
  handler : TMessageHandler;
begin
  handler :=
    procedure(const Msg : IMessage)
    begin
      WriteLn('MSG: '+Msg.AsString);
    end;
  TPubSub.Subscribe('/test',handler, 'testid');
  TPubSub.Subscribe('/test',
    procedure(const Msg : IMessage)
    begin
      WriteLn('MSG2: '+Msg.AsString);
    end
  , 'testid');
  Sleep(100);
  TPubSub.Publish('/test',TPubSub.NewMessage.Initialize('test','hello'));
  TPubSub.Publish('/test',TPubSub.NewMessage.Initialize('test2','hello2'));
  TPubSub.Publish('/test2',TPubSub.NewMessage.Initialize('test3','hello3'));
  TPubSub.UnSubscribe('/test',handler);
  TPubSub.Publish('/test',TPubSub.NewMessage.Initialize('test4','hello4'));
end;

procedure TestListenWait;
var
  msg: IMessage;
begin
  TThread.CreateAnonymousThread(
    procedure
    begin
      Sleep(3000);
      TPubSub.Publish('/test',TPubSub.NewMessage.Initialize('test5','hello5'));
    end
  ).Start;
  WriteLn('Waiting...');
  msg := TPubSub.ListenAndWait('/test');
  WriteLn('Waited: '+msg.AsString);
end;



procedure TestContext;
var
  ary: TArray<IMessage>;
  msg: IMessage;
begin
  TPubSub.BeginContext('/test','ThePipe');
  TPubSub.Publish('/test',TPubSub.NewMessage.Initialize('Pipetest','helloA'));
  TPubSub.Publish('/test',TPubSub.NewMessage.Initialize('Pipetest','helloB'));
  TPubSub.Publish('/test',TPubSub.NewMessage.Initialize('Pipetest','helloC'));
  WriteLn('Prefilled Pipe Test');
  ary := TPubSub.ListenAndWait('/test','ThePipe');
  for msg in ary do
  begin
    WriteLn('Q: '+msg.AsString);
  end;

  WriteLn('Evented Pipe Test');
  TThread.CreateAnonymousThread(
    procedure
    begin
      Sleep(3000);
      TPubSub.Publish('/test',TPubSub.NewMessage.Initialize('Pipetest2','helloD'));
    end
  ).Start;
  ary := TPubSub.ListenAndWait('/test','ThePipe');
  for msg in ary do
  begin
    WriteLn('Q2: '+msg.AsString);
  end;
end;

end.
