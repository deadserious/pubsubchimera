PubSub Chimera is an Open Source (MIT License) library for Delphi which provides a fast and cross platform PubSub and Message Queue implementation under a license that doesn't suck.

PubSub Chimera is a sister project to [JSON Chimera](https://code.google.com/p/jsonchimera).

Here is a very simple example of how to use PubSub Chimera.

```
uses
  chimera.pubsub;

begin
  TPubSub.Subscribe('/my_channel', 
    procedure(const msg : IMessage)
    begin
      DoSomethingWithMsg(msg);
    end
  );

  TPubSub.Publish('/my_channel', TPubSub.NewMessage.Initialize('name','data','text/plain'));
end.
```

You can use any object type as a message:

```
TPubSub<IJSONObject>.Subscribe('/my_channel', 
  procedure(const msg : IJSONObject)
  begin
    DoSomethingWithMsg(msg);
  end
);

  TPubSub<IJSONObject>.Publish('/my_channel', JSON('{"prop":"value"}');
```

Channels can be treated also be treated as queues:
```
var
  ary: TArray<IMessage>;
  msg: IMessage;
begin
  TPubSub.BeginQueue('/test','MyUniqueQueueID');
  TPubSub.Publish('/test',TPubSub.NewMessage.Initialize('queuetest','helloA'));
  TPubSub.Publish('/test',TPubSub.NewMessage.Initialize('queuetest','helloB'));
  TPubSub.Publish('/test',TPubSub.NewMessage.Initialize('queuetest','helloC'));

  // returns immediately since items are already in the queue
  ary := TPubSub.ListenAndWait('/test','MyUniqueQueueID');
  for msg in ary do
  begin
    DoSomethingWithMsg(msg);
  end;

  TThread.CreateAnonymousThread(
    procedure
    begin
      Sleep(3000);
      TPubSub.Publish('/test',TPubSub.NewMessage.Initialize('queuetest2','helloD'));
    end
  ).Start;

  // returns when new items have arrived in the queue.
  ary := TPubSub.ListenAndWait('/test','MyUniqueQueueID');
  for msg in ary do
  begin
    DoSomethingWithMsg(msg);
  end;
end;
```

There is also a WebModule Producer component for implementing pub/sub channels in your WebBroker applications.

The core Chimera library is intended to be very lightweight, fast, simple and thread safe.
