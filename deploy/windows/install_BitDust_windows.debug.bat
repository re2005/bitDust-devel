@echo off


set CURRENT_PATH=%cd%
set BITDUST_FULL_HOME=%HOMEDRIVE%%HOMEPATH%\.bitdust
echo Destination folder is %BITDUST_FULL_HOME%


if exist "%BITDUST_FULL_HOME%\python\python.exe" goto StartInstall


python --version 1>NUL 2>NUL
if errorlevel 1 goto StartInstall
reg query "hkcu\software\Python"
if errorlevel 1 goto StartInstall
reg query "hklm\software\Python"
if errorlevel 1 goto StartInstall


echo Python already installed on your machine.
echo Please install BitDust software manually by following this howto: 
echo     http://bitdust.io/install.html
pause
exit 


:StartInstall
echo Start installation
SET CURRENT_PATH=%cd%


if not exist "%BITDUST_FULL_HOME%" echo Prepare destination folder %BITDUST_FULL_HOME%
if not exist "%BITDUST_FULL_HOME%" mkdir "%BITDUST_FULL_HOME%"


set SHORT_PATH_SCRIPT=%BITDUST_FULL_HOME%\shortpath.bat
set SHORT_PATH_OUT=%BITDUST_FULL_HOME%\shortpath.txt
echo @echo OFF > "%SHORT_PATH_SCRIPT%"
echo echo %%~s1 >> "%SHORT_PATH_SCRIPT%"
call "%SHORT_PATH_SCRIPT%" "%BITDUST_FULL_HOME%" > "%SHORT_PATH_OUT%"
set /P BITDUST_HOME_0=<"%SHORT_PATH_OUT%"
call :StripHome %BITDUST_HOME_0%
:StripHome
set BITDUST_HOME=%1
echo Short and safe path is %BITDUST_HOME%
del /Q "%SHORT_PATH_OUT%"
del /Q "%SHORT_PATH_SCRIPT%"


set TMPDIR=%TEMP%\BitDust_Install_TEMP
rem set TMPDIR=%TEMP%\BitDust_Install_TEMP.%RANDOM%
rem if exist "%TMPDIR%\NUL" rmdir /S /Q %TMPDIR%
rem mkdir %TMPDIR%
if not exist %TMPDIR%\site-packages mkdir %TMPDIR%\site-packages
echo Prepared a temp folder %TMPDIR%


cd /D %TMPDIR%


echo Checking wget.exe
if exist wget0.exe goto WGetDownloaded


set DLOAD_SCRIPT="download.vbs"
echo Option Explicit                                                    >  %DLOAD_SCRIPT%
echo Dim args, http, fileSystem, adoStream, url, target, status         >> %DLOAD_SCRIPT%
echo.                                                                   >> %DLOAD_SCRIPT%
echo Set args = Wscript.Arguments                                       >> %DLOAD_SCRIPT%
echo Set http = CreateObject("WinHttp.WinHttpRequest.5.1")              >> %DLOAD_SCRIPT%
echo url = args(0)                                                      >> %DLOAD_SCRIPT%
echo target = args(1)                                                   >> %DLOAD_SCRIPT%
echo.                                                                   >> %DLOAD_SCRIPT%
echo http.Open "GET", url, False                                        >> %DLOAD_SCRIPT%
echo http.Send                                                          >> %DLOAD_SCRIPT%
echo status = http.Status                                               >> %DLOAD_SCRIPT%
echo.                                                                   >> %DLOAD_SCRIPT%
echo If status ^<^> 200 Then                                            >> %DLOAD_SCRIPT%
echo    WScript.Echo "FAILED to download: HTTP Status " ^& status       >> %DLOAD_SCRIPT%
echo    WScript.Quit 1                                                  >> %DLOAD_SCRIPT%
echo End If                                                             >> %DLOAD_SCRIPT%
echo.                                                                   >> %DLOAD_SCRIPT%
echo Set adoStream = CreateObject("ADODB.Stream")                       >> %DLOAD_SCRIPT%
echo adoStream.Open                                                     >> %DLOAD_SCRIPT%
echo adoStream.Type = 1                                                 >> %DLOAD_SCRIPT%
echo adoStream.Write http.ResponseBody                                  >> %DLOAD_SCRIPT%
echo adoStream.Position = 0                                             >> %DLOAD_SCRIPT%
echo.                                                                   >> %DLOAD_SCRIPT%
echo Set fileSystem = CreateObject("Scripting.FileSystemObject")        >> %DLOAD_SCRIPT%
echo If fileSystem.FileExists(target) Then fileSystem.DeleteFile target >> %DLOAD_SCRIPT%
echo adoStream.SaveToFile target                                        >> %DLOAD_SCRIPT%
echo adoStream.Close                                                    >> %DLOAD_SCRIPT%
echo.                                                                   >> %DLOAD_SCRIPT%


echo Downloading wget.exe
cscript //Nologo %DLOAD_SCRIPT% https://mingw-and-ndk.googlecode.com/files/wget.exe wget0.exe
:WGetDownloaded


if exist unzip.exe goto UnZIPDownloaded 
echo Downloading unzip.exe
wget0.exe -nv http://www2.cs.uidaho.edu/~jeffery/win32/unzip.exe --no-check-certificate 
:UnZIPDownloaded


echo Stopping Python instances
tasklist /FI "IMAGENAME eq bitdust.exe" 2>NUL | c:\windows\system32\find.exe /I /N "bitdust.exe" >NUL && ( taskkill  /IM bitdust.exe /F /T )
tasklist /FI "IMAGENAME eq bpstarter.exe" 2>NUL | c:\windows\system32\find.exe /I /N "bpstarter.exe" >NUL && ( taskkill  /IM bpstarter.exe /F /T )
tasklist /FI "IMAGENAME eq bpgui.exe" 2>NUL | c:\windows\system32\find.exe /I /N "bpgui.exe" >NUL && ( taskkill  /IM bpgui.exe /F /T )
tasklist /FI "IMAGENAME eq bppipe.exe" 2>NUL | c:\windows\system32\find.exe /I /N "bppipe.exe" >NUL && ( taskkill  /IM bppipe.exe /F /T )
tasklist /FI "IMAGENAME eq bptester.exe" 2>NUL | c:\windows\system32\find.exe /I /N "bptester.exe" >NUL && ( taskkill  /IM bptester.exe /F /T )
tasklist /FI "IMAGENAME eq python.exe" >NUL | c:\windows\system32\find.exe /I /N "python.exe" >NUL && ( taskkill  /IM python.exe /F /T )
tasklist /FI "IMAGENAME eq pythonw.exe" >NUL | c:\windows\system32\find.exe /I /N "pythonw.exe" >NUL && ( taskkill  /IM pythonw.exe /F /T )


echo Checking for python binaries in the destination folder
if exist %BITDUST_HOME%\python\python.exe goto PythonInstalled


if exist python-2.7.9.msi goto PythonDownloaded 
echo Downloading python-2.7.9.msi
wget0.exe  https://www.python.org/ftp/python/2.7.9/python-2.7.9.msi --no-check-certificate 
:PythonDownloaded
echo Extracting python-2.7.9.msi to %BITDUST_HOME%\python
if not exist %BITDUST_HOME%\python mkdir %BITDUST_HOME%\python
set EXTRACT_SCRIPT="msiextract.vbs"
echo Set args = Wscript.Arguments > %EXTRACT_SCRIPT%
echo Set objShell = CreateObject("Wscript.Shell") >> %EXTRACT_SCRIPT%
echo objCommand ^= ^"msiexec /a ^" ^& Chr(34) ^& args(0) ^& Chr(34) ^& ^" /qb TargetDir^=^" ^& Chr(34) ^& args(1) ^& Chr(34) >> %EXTRACT_SCRIPT%
echo objShell.Run objCommand, 1, true >> %EXTRACT_SCRIPT%
cscript //Nologo %EXTRACT_SCRIPT% python-2.7.9.msi %BITDUST_HOME%\python
rem msiexec /i python-2.7.9.msi /qb /norestart /l python-2.7.9.install.log TARGETDIR=%BITDUST_HOME%\python ALLUSERS=1
rem set msierror=%errorlevel%
rem if %msierror%==0 goto :PythonInstalled
rem if %msierror%==1641 goto :PythonInstalled
rem if %msierror%==3010 goto :PythonInstalled
rem echo Installation of Python was interrupter, exit code is %msierror%.
rem pause
rem exit
echo Verifying Python binaries
if exist %BITDUST_HOME%\python\python.exe goto PythonInstalled
echo Python installation to %BITDUST_HOME%\python was failed!
pause
exit
:PythonInstalled


echo Checking Python version
%BITDUST_HOME%\python\python.exe --version
if errorlevel 0 goto ContinueInstall
echo Python installation to %BITDUST_HOME%\python is corrupted!
pause
exit
:ContinueInstall


echo Installing setuptools
wget0 -nv https://bootstrap.pypa.io/ez_setup.py --no-check-certificate 
%BITDUST_HOME%\python\python.exe ez_setup.py


echo Checking for git binaries in the destination folder
if exist %BITDUST_HOME%\git\bin\git.exe goto GitInstalled


if exist Git-1.9.5-preview20150319.exe goto GitDownloaded 
echo Downloading Git-1.9.5-preview20150319.exe
wget0.exe -nv https://github.com/msysgit/msysgit/releases/download/Git-1.9.5-preview20150319/Git-1.9.5-preview20150319.exe --no-check-certificate 
:GitDownloaded
echo Installing Git-1.9.5-preview20150319.exe to %BITDUST_HOME%\git
if not exist %BITDUST_HOME%\git mkdir "%BITDUST_HOME%\git"
Git-1.9.5-preview20150319.exe /DIR="%BITDUST_HOME%\git" /NOICONS /SILENT /NORESTART /COMPONENTS=""
:GitInstalled


echo Checking for PyWin32 installed
if exist %BITDUST_HOME%\python\Lib\site-packages\win32\win32api.pyd goto PyWin32Installed
if exist pywin32-219.win32-py2.7.exe goto PyWin32Downloaded 
echo Downloading pywin32-219.win32-py2.7.exe
wget0.exe -nv "http://sourceforge.net/projects/pywin32/files/pywin32/Build 219/pywin32-219.win32-py2.7.exe/download" -O "%TMPDIR%\pywin32-219.win32-py2.7.exe" 
:PyWin32Downloaded
echo Installing pywin32-219.win32-py2.7.exe
unzip.exe -o -q pywin32-219.win32-py2.7.exe -d pywin32
xcopy pywin32\PLATLIB\*.* %BITDUST_HOME%\python\Lib\site-packages /E /I /Q /Y
:PyWin32Installed


echo Checking for PyCrypto installed
if exist %BITDUST_HOME%\python\Lib\site-packages\Crypto\__init__.py goto PyCryptoInstalled
if exist pycrypto-2.6.win32-py2.7.exe  goto PyCryptoDownloaded 
echo Downloading pycrypto-2.6.win32-py2.7.exe
wget0.exe -nv "http://www.voidspace.org.uk/downloads/pycrypto26/pycrypto-2.6.win32-py2.7.exe" 
:PyCryptoDownloaded
echo Installing pycrypto-2.6.win32-py2.7.exe
unzip.exe -o -q pycrypto-2.6.win32-py2.7.exe -d pycrypto
xcopy pycrypto\PLATLIB\*.* %BITDUST_HOME%\python\Lib\site-packages /E /I /Q /Y
:PyCryptoInstalled


echo Installing dependencies with easy_install
%BITDUST_HOME%\python\python.exe -m easy_install -Z -O -a -U -N zope.interface pyOpenSSL pyasn1 twisted Django==1.7


if not exist %BITDUST_HOME%\src echo Prepare sources folder
if not exist %BITDUST_HOME%\src mkdir %BITDUST_HOME%\src


cd /D %BITDUST_HOME%\src


if exist %BITDUST_HOME%\src\bitdust.py goto SourcesExist
echo Downloading BitDust software, use "git clone" command to get official public repository
%BITDUST_HOME%\git\bin\git.exe clone --depth 1 http://gitlab.bitdust.io/devel/bitdust.git .


:SourcesExist


echo Update sources
echo Running command "git clean"
%BITDUST_HOME%\git\bin\git.exe clean -d -fx "" 
echo Running command "git reset"
%BITDUST_HOME%\git\bin\git.exe reset --hard origin/master 
echo Running command "git pull"
%BITDUST_HOME%\git\bin\git.exe pull


echo Update binary extensions
xcopy deploy\windows\Python2.7.9\* %BITDUST_HOME%\python /E /H /R /Y 


cd /D %TMPDIR%


if not exist %BITDUST_HOME%\bin echo Create %BITDUST_HOME%\bin folder to make aliases for system commands
if not exist %BITDUST_HOME%\bin mkdir %BITDUST_HOME%\bin


echo Update system commands
echo @echo off > %BITDUST_HOME%\bin\bitdustd.bat
echo cd /D %BITDUST_HOME%\src >> %BITDUST_HOME%\bin\bitdustd.bat
echo call %BITDUST_HOME%\python\python.exe bitdust.py %%* >> %BITDUST_HOME%\bin\bitdustd.bat
echo pause >> %BITDUST_HOME%\bin\bitdustd.bat
echo @echo off > %BITDUST_HOME%\bin\bitdust.bat
echo cd /D %BITDUST_HOME%\src >> %BITDUST_HOME%\bin\bitdust.bat
echo start %BITDUST_HOME%\python\pythonw.exe bitdust.py %%* >> %BITDUST_HOME%\bin\bitdust.bat
echo exit >> %BITDUST_HOME%\bin\bitdust.bat
echo @echo off > %BITDUST_HOME%\bin\bitdust-sync.bat
echo cd /D %BITDUST_HOME%\src >> %BITDUST_HOME%\bin\bitdust-sync.bat
echo echo Running command "git clean" >> %BITDUST_HOME%\bin\bitdust-sync.bat
echo %BITDUST_HOME%\git\bin\git.exe clean -d -fx "" 1^>NUL >> %BITDUST_HOME%\bin\bitdust-sync.bat
echo echo Running command "git reset" >> %BITDUST_HOME%\bin\bitdust-sync.bat
echo %BITDUST_HOME%\git\bin\git.exe reset --hard origin/master >> %BITDUST_HOME%\bin\bitdust-sync.bat
echo echo Running command "git pull" >> %BITDUST_HOME%\bin\bitdust-sync.bat
echo %BITDUST_HOME%\git\bin\git.exe pull >> %BITDUST_HOME%\bin\bitdust-sync.bat
echo echo Running command "python manage.py syncdb" >> %BITDUST_HOME%\bin\bitdust-sync.bat
echo call %BITDUST_HOME%\python\python.exe manage.py syncdb >> %BITDUST_HOME%\bin\bitdust-sync.bat
echo pause >> %BITDUST_HOME%\bin\bitdust-sync.bat
echo @echo off > %BITDUST_HOME%\bin\bitdust-sync-restart.bat
echo cd /D %BITDUST_HOME%\src >> %BITDUST_HOME%\bin\bitdust-sync-restart.bat
echo call %BITDUST_HOME%\python\python.exe bitdust.py stop >> %BITDUST_HOME%\bin\bitdust-sync-restart.bat
echo echo Running command "git clean" >> %BITDUST_HOME%\bin\bitdust-sync-restart.bat
echo %BITDUST_HOME%\git\bin\git.exe clean -d -fx "" 1^>NUL >> %BITDUST_HOME%\bin\bitdust-sync-restart.bat
echo echo Running command "git reset" >> %BITDUST_HOME%\bin\bitdust-sync-restart.bat
echo %BITDUST_HOME%\git\bin\git.exe reset --hard origin/master >> %BITDUST_HOME%\bin\bitdust-sync-restart.bat
echo echo Running command "git pull" >> %BITDUST_HOME%\bin\bitdust-sync-restart.bat
echo %BITDUST_HOME%\git\bin\git.exe pull >> %BITDUST_HOME%\bin\bitdust-sync-restart.bat
echo echo Running command "python manage.py syncdb" >> %BITDUST_HOME%\bin\bitdust-sync-restart.bat
echo call %BITDUST_HOME%\python\python.exe manage.py syncdb >> %BITDUST_HOME%\bin\bitdust-sync-restart.bat
echo start %BITDUST_HOME%\python\pythonw.exe bitdust.py %%* >> %BITDUST_HOME%\bin\bitdust-sync-restart.bat
echo exit >> %BITDUST_HOME%\bin\bitdust-sync-restart.bat


echo Prepare Desktop icon
echo set WshShell = WScript.CreateObject("WScript.Shell") > find_desktop.vbs
echo strDesktop = WshShell.SpecialFolders("Desktop") >> find_desktop.vbs
echo wscript.echo(strDesktop) >> find_desktop.vbs
for /F "usebackq delims=" %%i in (`cscript find_desktop.vbs`) do set DESKTOP_DIR1=%%i
rem echo Desktop folder is %DESKTOP_DIR1%
set DESKTOP_REG_ENTRY="HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders"
set DESKTOP_REG_KEY="Desktop"
set DESKTOP_DIR2=
for /F "tokens=1,2*" %%a in ('REG QUERY %DESKTOP_REG_ENTRY% /v %DESKTOP_REG_KEY% ^| FINDSTR "REG_SZ"') do ( set DESKTOP_DIR2=%%c )
echo Desktop folder is %DESKTOP_DIR1%


echo Updating shortcuts
echo Set oWS = WScript.CreateObject("WScript.Shell") > CreateShortcut0.vbs
echo sLinkFile = "BitDust.lnk" >> CreateShortcut0.vbs
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> CreateShortcut0.vbs
echo oLink.TargetPath = "%BITDUST_HOME%" >> CreateShortcut0.vbs
echo oLink.Arguments = "" >> CreateShortcut0.vbs
echo oLink.WorkingDirectory = "%BITDUST_HOME%" >> CreateShortcut0.vbs
echo oLink.IconLocation = "%BITDUST_HOME%\src\icons\desktop.ico" >> CreateShortcut0.vbs
echo oLink.Description = "Open root folder of BitDust Software" >> CreateShortcut0.vbs
echo oLink.WindowStyle = "1" >> CreateShortcut0.vbs
echo oLink.Save >> CreateShortcut0.vbs
cscript //Nologo CreateShortcut0.vbs
xcopy BitDust.lnk "%DESKTOP_DIR2%" /Y


echo Set oWS = WScript.CreateObject("WScript.Shell") > CreateShortcut1.vbs
echo sLinkFile = "%BITDUST_HOME%\START.lnk" >> CreateShortcut1.vbs
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> CreateShortcut1.vbs
echo oLink.TargetPath = "%BITDUST_HOME%\bin\bitdust.bat" >> CreateShortcut1.vbs
echo oLink.Arguments = "show" >> CreateShortcut1.vbs
echo oLink.WorkingDirectory = "%BITDUST_HOME%\src" >> CreateShortcut1.vbs
echo oLink.IconLocation = "%BITDUST_HOME%\src\icons\desktop.ico" >> CreateShortcut1.vbs
echo oLink.Description = "Launch BitDust software in background mode" >> CreateShortcut1.vbs
echo oLink.WindowStyle = "2" >> CreateShortcut1.vbs
echo oLink.Save >> CreateShortcut1.vbs
cscript //Nologo CreateShortcut1.vbs


echo Set oWS = WScript.CreateObject("WScript.Shell") > CreateShortcut2.vbs
echo sLinkFile = "%BITDUST_HOME%\DEBUG.lnk" >> CreateShortcut2.vbs
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> CreateShortcut2.vbs
echo oLink.TargetPath = "%BITDUST_HOME%\bin\bitdustd.bat" >> CreateShortcut2.vbs
echo oLink.Arguments = "--debug=10 show" >> CreateShortcut2.vbs
echo oLink.WorkingDirectory = "%BITDUST_HOME%\src" >> CreateShortcut2.vbs
echo oLink.IconLocation = "%BITDUST_HOME%\src\icons\desktop-debug.ico" >> CreateShortcut2.vbs
echo oLink.Description = "Launch BitDust software in debug mode" >> CreateShortcut2.vbs
echo oLink.WindowStyle = "1" >> CreateShortcut2.vbs
echo oLink.Save >> CreateShortcut2.vbs
cscript //Nologo CreateShortcut2.vbs


echo Set oWS = WScript.CreateObject("WScript.Shell") > CreateShortcut3.vbs
echo sLinkFile = "%BITDUST_HOME%\STOP.lnk" >> CreateShortcut3.vbs
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> CreateShortcut3.vbs
echo oLink.TargetPath = "%BITDUST_HOME%\python\pythonw.exe" >> CreateShortcut3.vbs
echo oLink.Arguments = "bitdust.py stop" >> CreateShortcut3.vbs
echo oLink.WorkingDirectory = "%BITDUST_HOME%\src" >> CreateShortcut3.vbs
echo oLink.IconLocation = "%BITDUST_HOME%\src\icons\desktop-stop.ico" >> CreateShortcut3.vbs
echo oLink.Description = "Completely stop BitDust software" >> CreateShortcut3.vbs
echo oLink.WindowStyle = "1" >> CreateShortcut3.vbs
echo oLink.Save >> CreateShortcut3.vbs
cscript //Nologo CreateShortcut3.vbs


echo Set oWS = WScript.CreateObject("WScript.Shell") > CreateShortcut4.vbs
echo sLinkFile = "%BITDUST_HOME%\SYNCHRONIZE.lnk" >> CreateShortcut4.vbs
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> CreateShortcut4.vbs
echo oLink.TargetPath = "%BITDUST_HOME%\bin\bitdust-sync-restart.bat" >> CreateShortcut4.vbs
echo oLink.Arguments = "" >> CreateShortcut4.vbs
echo oLink.WorkingDirectory = "%BITDUST_HOME%\src" >> CreateShortcut4.vbs
echo oLink.IconLocation = "%BITDUST_HOME%\src\icons\desktop-sync.ico" >> CreateShortcut4.vbs
echo oLink.Description = "Synchronize BitDust sources from public repository at http://gitlab.bitdust.io/devel/bitdust/" >> CreateShortcut4.vbs
echo oLink.WindowStyle = "1" >> CreateShortcut4.vbs
echo oLink.Save >> CreateShortcut4.vbs
cscript //Nologo CreateShortcut4.vbs


echo Set oWS = WScript.CreateObject("WScript.Shell") > CreateShortcut5.vbs
echo sLinkFile = "%BITDUST_HOME%\SYNC&RESTART.lnk" >> CreateShortcut5.vbs
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> CreateShortcut5.vbs
echo oLink.TargetPath = "%BITDUST_HOME%\bin\bitdust-sync-restart.bat" >> CreateShortcut5.vbs
echo oLink.Arguments = "" >> CreateShortcut5.vbs
echo oLink.WorkingDirectory = "%BITDUST_HOME%\src" >> CreateShortcut5.vbs
echo oLink.IconLocation = "%BITDUST_HOME%\src\icons\desktop-sync.ico" >> CreateShortcut5.vbs
echo oLink.Description = "Synchronize BitDust sources from public repository at http://gitlab.bitdust.io/devel/bitdust/" >> CreateShortcut5.vbs
echo oLink.WindowStyle = "2" >> CreateShortcut5.vbs
echo oLink.Save >> CreateShortcut5.vbs
cscript //Nologo CreateShortcut5.vbs


cd /D %BITDUST_HOME%\src


echo Prepare Django db, run command "python manage.py syncdb"
call %BITDUST_HOME%\python\python.exe manage.py syncdb 


@echo.
echo ALL DONE !!!!!!
@echo.
echo A python script %HOMEDRIVE%%HOMEPATH%\.bitdust\src\bitdust.py is main entry point to run the software.
echo You can click on the new icon created on the desktop to open the root application folder.
echo Use shortcuts in there to control BitDust at any time:
echo     START :        execute the main process and/or open the web browser to access the user interface
echo     STOP:          stop (or kill) the main BitDust process completely
echo     SYNCHRONIZE:   update BitDust sources from the public repository
echo     SYNC^&RESTART:  update sources and restart the software softly in background
echo     DEBUG:         run the program in debug mode and watch the full log
@echo.
echo To be sure you are running the latest version use "SYNCHRONIZE" and "SYNC&RESTART" shortcuts.
echo You may want to copy "SYNC&RESTART" shortcut to Startup folder in the Windows Start menu to start the program during bootup process and keep it fresh and ready.
@echo.
echo Now executing "START" command and running BitDust software in background mode, this window can be closed now.
echo Your web browser will be opened at the moment and you will see the starting page.
@echo.
echo Welcome to the Bit Dust World !!!.
@echo.

cd /D "%BITDUST_HOME%"
"START.lnk"


cd /D %CURRENT_PATH%
@echo.


pause
exit