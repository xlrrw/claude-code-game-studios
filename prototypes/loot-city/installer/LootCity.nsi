; PROTOTYPE - NOT FOR PRODUCTION
; Per-user installer for Loot City (no admin rights needed).
Unicode true
SetCompressor /SOLID lzma
!include "MUI2.nsh"
Name "Loot City: Город возможностей"
OutFile "..\release\LootCity-Setup.exe"
InstallDir "$LOCALAPPDATA\Programs\Loot City"
InstallDirRegKey HKCU "Software\LootCity" "InstallDir"
RequestExecutionLevel user
BrandingText "Loot City 1.0"
!define MUI_ICON "icon.ico"
!define MUI_UNICON "icon.ico"
!define MUI_ABORTWARNING
!define MUI_FINISHPAGE_RUN "$INSTDIR\Loot City.exe"
!define MUI_FINISHPAGE_RUN_TEXT "Запустить Loot City"
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "Russian"
VIProductVersion "1.0.0.0"
VIAddVersionKey /LANG=${LANG_RUSSIAN} "ProductName" "Loot City"
VIAddVersionKey /LANG=${LANG_RUSSIAN} "FileDescription" "Установщик Loot City"
VIAddVersionKey /LANG=${LANG_RUSSIAN} "FileVersion" "1.0.0"
VIAddVersionKey /LANG=${LANG_RUSSIAN} "LegalCopyright" "Loot City"

Section "Install"
  SetOutPath "$INSTDIR"
  File /r "..\release\win-unpacked\*.*"
  File "icon.ico"
  WriteRegStr HKCU "Software\LootCity" "InstallDir" "$INSTDIR"
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  CreateDirectory "$SMPROGRAMS\Loot City"
  CreateShortCut "$SMPROGRAMS\Loot City\Loot City.lnk" "$INSTDIR\Loot City.exe" "" "$INSTDIR\icon.ico"
  CreateShortCut "$SMPROGRAMS\Loot City\Удалить Loot City.lnk" "$INSTDIR\Uninstall.exe"
  CreateShortCut "$DESKTOP\Loot City.lnk" "$INSTDIR\Loot City.exe" "" "$INSTDIR\icon.ico"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\LootCity" "DisplayName" "Loot City"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\LootCity" "UninstallString" '"$INSTDIR\Uninstall.exe"'
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\LootCity" "DisplayIcon" "$INSTDIR\icon.ico"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\LootCity" "DisplayVersion" "1.0.0"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\LootCity" "Publisher" "Loot City"
SectionEnd

Section "Uninstall"
  Delete "$DESKTOP\Loot City.lnk"
  RMDir /r "$SMPROGRAMS\Loot City"
  RMDir /r "$INSTDIR"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\LootCity"
  DeleteRegKey HKCU "Software\LootCity"
SectionEnd
