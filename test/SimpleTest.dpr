program SimpleTest;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  chimera.pubsub.test.simple in 'chimera.pubsub.test.simple.pas';

begin
  try
    { TODO -oUser -cConsole Main : Insert code here }
    TestPubSub;
    TestListenWait;
    TestQueue;
    ReadLn;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
