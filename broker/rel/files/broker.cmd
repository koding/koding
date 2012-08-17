@setlocal

@set node_name=broker

@rem Get the absolute path to the parent directory,
@rem which is assumed to be the node root.
@for /F "delims=" %%I in ("%~dp0..") do @set node_root=%%~fI

@set releases_dir=%node_root%\releases

@rem Parse ERTS version and release version from start_erl.data
@for /F "tokens=1,2" %%I in (%releases_dir%\start_erl.data) do @(
    @call :set_trim erts_version %%I
    @call :set_trim release_version %%J
)

@rem extract erlang cookie from vm.args
@set vm_args=%releases_dir%\%release_version%\vm.args
@for /f "usebackq tokens=1-2" %%I in (`findstr /b \-setcookie %vm_args%`) do @set erlang_cookie=%%J

@set erts_bin=%node_root%\erts-%erts_version%\bin

@set service_name=%node_name%_%release_version%

@if "%1"=="usage" @goto usage
@if "%1"=="install" @goto install
@if "%1"=="uninstall" @goto uninstall
@if "%1"=="start" @goto start
@if "%1"=="stop" @goto stop
@if "%1"=="restart" @call :stop && @goto start
@if "%1"=="console" @goto console
@if "%1"=="query" @goto query
@if "%1"=="attach" @goto attach
@if "%1"=="upgrade" @goto upgrade
@echo Unknown command: "%1"

:usage
@echo Usage: %~n0 [install^|uninstall^|start^|stop^|restart^|console^|query^|attach^|upgrade]
@goto :EOF

:install
@%erts_bin%\erlsrv.exe add %service_name% -c "Erlang node %node_name% in %node_root%" -sname %node_name% -w %node_root% -m %node_root%\bin\start_erl.cmd -args " ++ %node_name% ++ %node_root%" -stopaction "init:stop()."
@goto :EOF

:uninstall
@%erts_bin%\erlsrv.exe remove %service_name%
@%erts_bin%\epmd.exe -kill
@goto :EOF

:start
@%erts_bin%\erlsrv.exe start %service_name%
@goto :EOF

:stop
@%erts_bin%\erlsrv.exe stop %service_name%
@goto :EOF

:console
@start %erts_bin%\werl.exe -boot %releases_dir%\%release_version%\%node_name% -config %releases_dir%\%release_version%\sys.config -args_file %vm_args% -sname %node_name%
@goto :EOF

:query
@%erts_bin%\erlsrv.exe list %service_name%
@exit /b %ERRORLEVEL%
@goto :EOF

:attach
@for /f "usebackq" %%I in (`hostname`) do @set hostname=%%I
start %erts_bin%\werl.exe -boot %releases_dir%\%release_version%\start_clean -remsh %node_name%@%hostname% -sname console -setcookie %erlang_cookie%
@goto :EOF

:upgrade
@if "%2"=="" (
    @echo Missing upgrade package argument
    @echo Usage: %~n0 upgrade {package base name}
    @echo NOTE {package base name} MUST NOT include the .tar.gz suffix
    @goto :EOF
)
@%erts_bin%\escript.exe %node_root%\bin\install_upgrade.escript %node_name% %erlang_cookie% %2
@goto :EOF

:set_trim
@set %1=%2
@goto :EOF
