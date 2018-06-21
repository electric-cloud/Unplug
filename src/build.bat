@echo off
set COMMANDER_SERVER=flow
ectool --server %COMMANDER_SERVER% login admin changeme
set COMMANDER_HOME=C:\Program Files\Electric Cloud\ElectricCommander
set JAVA_HOME=C:\Program Files\Java\jdk1.8.0_161
set antPath=C:\Program Files\Electric Cloud\CommanderSDK\tools\ant\bin\ant
"%antPath%" build deploy package.post