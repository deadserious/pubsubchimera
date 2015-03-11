object WebModule1: TWebModule1
  OldCreateOrder = False
  Actions = <
    item
      Name = 'WebActionItem1'
      PathInfo = '/pubsub'
      Producer = PubSubProducer1
    end
    item
      Default = True
      Name = 'DefaultHandler'
      PathInfo = '/'
      OnAction = WebModule1DefaultHandlerAction
    end>
  Height = 230
  Width = 415
  object PubSubProducer1: TPubSubProducer
    OnSession = PubSubProducer1Session
    Left = 192
    Top = 96
  end
end
