!macro CustomCodePostInstall
	CopyFiles /SILENT "$INSTDIR\Other\Source\HostsManPortable.ini" "$INSTDIR"
!macroend