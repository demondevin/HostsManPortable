
;= VARIABLES
;= ################
Var Admin

;= DEFINES
;= ################
!define APP		`HostsMan`
!define APPNAME	`${APP}Portable`
!define APPDIR	`$EXEDIR\App\${APP}`
!define DATA	`$EXEDIR\Data`
!define SET		`${DATA}\settings`
!define DEFDATA	`$EXEDIR\App\DefaultData`
!define DEFSET	`${DEFDATA}\settings`
!define SETINI	`${SET}\${APPNAME}Settings.ini`
!define CONFIG	`$EXEDIR\${APPNAME}.ini`
!define INI		`${SET}\hm.ini`
!define DEFINI	`${DEFDATA}\settings\hm.ini`
!define CFG		`${DATA}\${APP}\prefs.cfg`
!define DEFCFG	`${DEFDATA}\${APP}\prefs.cfg`
!define BACKUP	`${DATA}\Backups`
!define HOSTS	`$SYSDIR\drivers\etc\hosts`
!define BAK		`${BACKUP}\hosts.BackupBy${APPNAME}`
!define GETPRC	`kernel32::GetCurrentProcess()i.s`
!define WOW		`kernel32::IsWow64Process(is,*i.r0)`
!define HALTFSR `kernel32::Wow64EnableWow64FsRedirection(i0)`
!define G		`Kernel32::GetVolumeInformation(t,t,i,*i,*i,*i,t,i) i`
!define GET		`${G}("$0",,${NSIS_MAX_STRLEN},.r0,,,,${NSIS_MAX_STRLEN})`
!define ID		`Kernel32::SetEnvironmentVariable(t "LastUniqueID", t "$0")`

;= FUNCTIONS
;= ################
Function IsWOW64
	!define IsWOW64 `!insertmacro _IsWOW64`
	!macro _IsWOW64 _RETURN
		Push ${_RETURN}
		Call IsWOW64
		Pop ${_RETURN}
	!macroend
	Exch $0
	System::Call `${GETPRC}`
	System::Call `${WOW}`
	Exch $0
FunctionEnd

;= CUSTOM 
;= ################
${SegmentFile}
${Segment.OnInit}
	Push $0
	${IsWOW64} $0
	StrCmp $0 0 0 +3
	WriteINIStr `${SETINI}` ${APPNAME}Settings Architecture 32
		Goto END
	System::Call ${HALTFSR}
	WriteINIStr `${SETINI}` ${APPNAME}Settings Architecture 64
	END:
	Pop $0
	${If} ${IsNT}
		${If} ${IsWinXP}
			${IfNot} ${AtLeastServicePack} 2
				MessageBox MB_ICONSTOP|MB_TOPMOST `${APPNAME} requires Service Pack 2 or newer`
				Call Unload
				Quit
			${EndIf}
		${ElseIfNot} ${AtLeastWinXP}
			MessageBox MB_ICONSTOP|MB_TOPMOST `${APPNAME} requires Windows XP or newer`
			Call Unload
			Quit
		${EndIf}
	${Else}
		MessageBox MB_ICONSTOP|MB_TOPMOST `${APPNAME} requires Windows XP or newer`
		Call Unload
		Quit
	${EndIf}
	System::Call `kernel32::GetModuleHandle(t 'shell32.dll') i .s`
	System::Call `kernel32::GetProcAddress(i s, i 680) i .r0`
	System::Call `::$0() i .r0`
	StrCmpS $0 1 "" +2
	StrCpy $Admin true
	IfFileExists `${INI}` +2
	CopyFiles /SILENT `${DEFINI}` `${INI}`
	IfFileExists `${CFG}` +3
	CreateDirectory `${DATA}\${APP}`
	CopyFiles /SILENT `${DEFCFG}` `${CFG}`
	IfFileExists `${BACKUP}` +2
	CreateDirectory `${BACKUP}`
!macroend
${SegmentPrePrimary}
	ReadINIStr $0 ${CONFIG} ${APPNAME} CheckBackUpHost
	StrCmp $0 true TRUE SKIP
	TRUE:
		IfFileExists `${BAK}` 0 SKIP
		MessageBox MB_YESNO|MB_TOPMOST "You have a backup HOSTS file. Would you like to replace the host PC's file with your backup?$\r$\n$\r$\nThe host PC's HOST file will be preserved." IDYES YES IDNO SKIP
		YES:
			StrCmpS $Admin true +3 0
			MessageBox MB_OK|MB_TOPMOST `You must have administrative privileges in order to continue with this task. Please restart ${APPNAME} with administrative rights.$\r$\n$\r$\nThe host file-system has not been changed.`
				Goto SKIP
			Rename `${HOSTS}` `${HOSTS}.BackupBy${APPNAME}`
			CopyFiles /SILENT `${BAK}` `${HOSTS}`
			MessageBox MB_OK|MB_TOPMOST `The host PC's HOST file has been renamed to:$\r$\n${HOSTS}.BackupBy${APPNAME}$\r$\n$\r$\nIt will be restored on exit.`
	SKIP:
!macroend
${SegmentPostPrimary}
	ReadINIStr $0 ${CONFIG} ${APPNAME} CheckBackUpHost
	StrCmp $0 true 0 +5
	IfFileExists `${HOSTS}.BackupBy${APPNAME}` 0 +4
	Delete `${BAK}`
	Rename `${HOSTS}` `${BAK}`
	Rename `${HOSTS}.BackupBy${APPNAME}` `${HOSTS}`
!macroend