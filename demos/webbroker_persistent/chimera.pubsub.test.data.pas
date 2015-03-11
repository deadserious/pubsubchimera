// *****************************************************************************
//
// chimera.pubsub.test.data;
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

unit chimera.pubsub.test.data;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Phys, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys.IBBase,
  FireDAC.Phys.FB, Data.DB, FireDAC.Comp.Client, chimera.pubsub, chimera.json,
  System.SyncObjs, System.Generics.Collections, FireDAC.VCLUI.Wait,
  FireDAC.VCLUI.Error, FireDAC.VCLUI.Script, FireDAC.VCLUI.Async,
  FireDAC.VCLUI.Login, FireDAC.Comp.UI, FireDAC.DApt;

type
  TDataModule1 = class(TDataModule)
    FDManager1: TFDManager;
    FDConnection1: TFDConnection;
    FDPhysFBDriverLink1: TFDPhysFBDriverLink;
    FDGUIxWaitCursor1: TFDGUIxWaitCursor;
    FDGUIxErrorDialog1: TFDGUIxErrorDialog;
    FDGUIxScriptDialog1: TFDGUIxScriptDialog;
    FDGUIxAsyncExecuteDialog1: TFDGUIxAsyncExecuteDialog;
    FDGUIxLoginDialog1: TFDGUIxLoginDialog;
    procedure DataModuleCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  DataModule1: TDataModule1;

implementation

uses chimera.pubsub.producer;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}


procedure TDataModule1.DataModuleCreate(Sender: TObject);
begin
  FDPhysFBDriverLink1.VendorLib := ExtractFilePath(ParamStr(0))+'fbembed.dll';
  FDConnection1.Params.Clear;
  FDConnection1.Params.Add('DriverID=FB');
  FDConnection1.Params.Add('Database='+ExtractFilePath(ParamStr(0))+'CHANNEL_DATA.FDB');
  FDConnection1.Params.Add('User_Name=sysdba');
  FDConnection1.Params.Add('CharacterSet=utf8');
  FDConnection1.Connected := True;

  TPubSubProducer.PubSub.OnReloadContext :=
    procedure(const channel : IChannel<IJSONObject>; const Context : String; Queue : TQueue<IJSONObject>)
    var
      qry : TFDQuery;
      cxt : string;
    begin
      qry := TFDQuery.Create(nil);
      try
        qry.ConnectionName := 'PubSubData';

        qry.SQL.Text := 'select CHANNEL from KNOWN_CONTEXTS where CHANNEL = :Channel and CONTEXT = :Context';
        qry.ParamByName('Channel').AsString := Channel.Name;
        qry.ParamByName('Context').AsString := Context;
        qry.Open;

        if qry.Eof then
        begin
          cxt := '';

          qry.SQL.Text := 'insert into MESSAGES (STAMP, CHANNEL, CONTEXT, DATA) select STAMP, Channel, :Context, Data from MESSAGES where Channel = :Channel and Context = ''''';
          qry.ParamByName('Channel').AsString := Channel.Name;
          qry.ParamByName('Context').AsString := Context;
          qry.ExecSQL;

          qry.SQL.Text := 'insert into KNOWN_CONTEXTS (CHANNEL, CONTEXT) values (:Channel, :Context)';
          qry.ParamByName('Channel').AsString := Channel.Name;
          qry.ParamByName('Context').AsString := Context;
          qry.ExecSQL;
        end else
          cxt := Context;


        qry.SQL.Text := 'select DATA from MESSAGES where CHANNEL = :Channel and CONTEXT = :Context';
        qry.ParamByName('Channel').AsString := Channel.Name;
        qry.ParamByName('Context').AsString := cxt;
        qry.Open;
        while not qry.EOF do
        begin
          Queue.Enqueue(JSON(qry.FieldByName('DATA').AsString));
          qry.Next;
        end;
      finally
        qry.Free;
      end;
    end;

  TPubSubProducer.PubSub.OnStoreMessage :=
    procedure(const channel : IChannel<IJSONObject>; const Context : string; Data : IJSONObject )
    var
      qry : TFDQuery;
    begin
      qry := TFDQuery.Create(nil);
      try
        qry.ConnectionName := 'PubSubData';
        qry.SQL.Text := 'insert into MESSAGES (STAMP, CHANNEL, CONTEXT, DATA) values (CURRENT_TIMESTAMP, :Channel, :Context, :Data)';
        qry.ParamByName('Channel').AsString := Channel.Name;
        qry.ParamByName('Context').AsString := Context;
        qry.ParamByName('Data').AsString := Data.AsJSON;
        qry.ExecSQL;
      finally
        qry.Free;
      end;
    end;

  TPubSubProducer.PubSub.OnClearMessage :=
    procedure(const channel : IChannel<IJSONObject>; const Context : string; Data : IJSONObject )
    var
      qry : TFDQuery;
    begin
      if Context = '' then
        exit;
      qry := TFDQuery.Create(nil);
      try
        qry.ConnectionName := 'PubSubData';
        qry.SQL.Text := 'update MESSAGES set DELIVERED = CURRENT_TIMESTAMP where CHANNEL = :Channel and CONTEXT = :Context and DATA = :Data';
        qry.ParamByName('Channel').AsString := Channel.Name;
        qry.ParamByName('Context').AsString := Context;
        qry.ParamByName('Data').AsString := Data.AsJSON;
        qry.ExecSQL;
      finally
        qry.Free;
      end;
    end;

end;


end.
