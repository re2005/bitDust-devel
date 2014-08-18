@echo off


@echo.
@echo [ prepare uploading ]
if exist upload\NUL rmdir /S /Q upload
mkdir upload
mkdir upload\bin
xcopy bin\* upload\bin\    /E /R /H /Y /Q
xcopy files upload\    /Y /Q
xcopy checksum upload\  /Y /Q


REM @echo.
REM @echo [ validating repository files ]
REM rsync.exe -rptgoE --delete --force -z --compress-level=9 -h --progress -n --stats -c  upload/* rsync://veselin@bitpie.net/test
REM pause


@echo.
@echo [ upload using rsync into "test" repository ]
rsync.exe -rptgoE --delete --force -z --compress-level=9 -h --progress -vv --stats -c  upload/* rsync://veselin@bitpie.net/test


@echo.
@echo [DONE]


pause 