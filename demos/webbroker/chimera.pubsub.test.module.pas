// *****************************************************************************
//
// chimera.pubsub.test.module;
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

unit chimera.pubsub.test.module;

interface

uses System.SysUtils, System.Classes, Web.HTTPApp, Web.HTTPProd,
  chimera.pubsub.producer;

type
  TWebModule1 = class(TWebModule)
    PubSubProducer1: TPubSubProducer;
    procedure WebModule1DefaultHandlerAction(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
    procedure PubSubProducer1Session(Sender: TObject; Request: TWebRequest;
      Response: TWebResponse; var ID: string);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  WebModuleClass: TComponentClass = TWebModule1;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TWebModule1.PubSubProducer1Session(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var ID: string);
begin
  ID := Request.CookieFields.Values['pubsub_id'];
end;

procedure TWebModule1.WebModule1DefaultHandlerAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
var
  cookie: TCookie;
  g : TGUID;
begin
  Response.ContentStream := TFileStream.Create(ExtractFilePath(ParamStr(0))+'index.html', fmOpenRead or fmShareDenyNone);
  Response.ContentType := 'text/html';

  if Request.CookieFields.Values['pubsub_id'] = '' then
  begin
    cookie := Response.Cookies.Add;
    cookie.Path := '/';
    cookie.Expires := Now+100;
    cookie.Name := 'pubsub_id';
    CreateGuid(g);
    cookie.Value := GuidToString(g); // not a safe practice but good enough for demo purposes.
  end;
end;

end.
