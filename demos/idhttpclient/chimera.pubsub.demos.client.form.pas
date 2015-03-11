// *****************************************************************************
//
// chimera.pubsub.demos.client.form;
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

unit chimera.pubsub.demos.client.form;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, chimera.json,
  chimera.pubsub.client.idhttp;

type
  TForm2 = class(TForm)
    PubSubHTTPClient1: TPubSubHTTPClient;
    txtUsername: TEdit;
    Label1: TLabel;
    txtMessage: TEdit;
    Label2: TLabel;
    btnSend: TButton;
    txtChat: TMemo;
    procedure btnSendClick(Sender: TObject);
    procedure PubSubHTTPClient1Message(Sender: TObject; const Msg: IJSONObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

implementation

{$R *.dfm}

procedure TForm2.btnSendClick(Sender: TObject);
var
  jso : IJSONObject;
begin
  jso := JSON;
  jso.Strings['user'] := txtUsername.Text;
  jso.Strings['message'] := txtMessage.Text;

  PubSubHTTPClient1.Publish('/pubsub',jso);
end;

procedure TForm2.FormCreate(Sender: TObject);
begin
  PubSubHTTPClient1.Subscribe('/pubsub');
end;

procedure TForm2.PubSubHTTPClient1Message(Sender: TObject;
  const Msg: IJSONObject);
var
  sUser : string;
begin
  sUser := Msg.Strings['user']+':';
  if sUser = ':' then
    sUser := 'Anonymous:';

  txtChat.Lines.Insert(0,sUser+' '+Msg.Strings['message']);
end;

end.
