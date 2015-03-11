object Form2: TForm2
  Left = 0
  Top = 0
  Caption = 'Form2'
  ClientHeight = 299
  ClientWidth = 635
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  DesignSize = (
    635
    299)
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 48
    Height = 13
    Caption = 'Username'
  end
  object Label2: TLabel
    Left = 135
    Top = 8
    Width = 46
    Height = 13
    Caption = 'Message:'
  end
  object txtUsername: TEdit
    Left = 8
    Top = 24
    Width = 121
    Height = 21
    TabOrder = 0
  end
  object txtMessage: TEdit
    Left = 135
    Top = 24
    Width = 411
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 1
  end
  object btnSend: TButton
    Left = 552
    Top = 22
    Width = 75
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Send'
    TabOrder = 2
    OnClick = btnSendClick
  end
  object txtChat: TMemo
    Left = 8
    Top = 51
    Width = 619
    Height = 240
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 3
  end
  object PubSubHTTPClient1: TPubSubHTTPClient
    Host = 'http://127.0.0.1'
    Port = 8080
    OnMessage = PubSubHTTPClient1Message
    Left = 512
    Top = 72
  end
end
