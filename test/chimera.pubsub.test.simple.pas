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

uses System.SysUtils;

procedure TestPubSub;
procedure TestListenWait;
procedure TestQueue;

implementation

uses chimera.pubsub, system.Classes;

procedure TestPubSub;
var
  handler : TMessageHandler;
begin
  handler :=
    procedure(const Msg : IMessage)
    begin
      WriteLn('MSG: '+Msg.AsString);
    end;
  TPubSub.Subscribe('/test',handler);
  TPubSub.Subscribe('/test',
    procedure(const Msg : IMessage)
    begin
      WriteLn('MSG2: '+Msg.AsString);
    end
  );
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

procedure TestQueue;
var
  ary: TArray<IMessage>;
  msg: IMessage;
begin
  TPubSub.BeginQueue('/test','TheQueue');
  TPubSub.Publish('/test',TPubSub.NewMessage.Initialize('queuetest','helloA'));
  TPubSub.Publish('/test',TPubSub.NewMessage.Initialize('queuetest','helloB'));
  TPubSub.Publish('/test',TPubSub.NewMessage.Initialize('queuetest','helloC'));
  WriteLn('Prefilled Queue Test');
  ary := TPubSub.ListenAndWait('/test','TheQueue');
  for msg in ary do
  begin
    WriteLn('Q: '+msg.AsString);
  end;

  WriteLn('Evented Queue Test');
  TThread.CreateAnonymousThread(
    procedure
    begin
      Sleep(3000);
      TPubSub.Publish('/test',TPubSub.NewMessage.Initialize('queuetest2','helloD'));
    end
  ).Start;
  ary := TPubSub.ListenAndWait('/test','TheQueue');
  for msg in ary do
  begin
    WriteLn('Q2: '+msg.AsString);
  end;
end;

end.
