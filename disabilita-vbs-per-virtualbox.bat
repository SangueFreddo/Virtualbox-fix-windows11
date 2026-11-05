@echo off
REM ============================================================
REM Disabilita COMPLETA di Hyper-V / VBS / Device Guard /
REM Isolamento core / Credential Guard + servizi e feature
REM dipendenti, per far girare bene VirtualBox su Windows 11
REM ESEGUIRE COME AMMINISTRATORE
REM ============================================================
 
echo [1/5] Disabilito hypervisor e feature Windows principali...
bcdedit /set hypervisorlaunchtype off
dism.exe /online /disable-feature /featurename:Microsoft-Hyper-V-All /norestart
dism.exe /online /disable-feature /featurename:HypervisorPlatform /norestart
dism.exe /online /disable-feature /featurename:VirtualMachinePlatform /norestart
 
echo [2/5] Disabilito feature dipendenti da VBS (sandbox, WSL, App Guard)...
dism.exe /online /disable-feature /featurename:Containers-DisposableClientVM /norestart
dism.exe /online /disable-feature /featurename:Microsoft-Windows-Subsystem-Linux /norestart
dism.exe /online /disable-feature /featurename:Windows-Defender-ApplicationGuard /norestart
dism.exe /online /disable-feature /featurename:HostGuardian /norestart
 
echo [3/5] Disabilito Isolamento core / Memory Integrity / VBS / Credential Guard via registro...
REM Memory Integrity (Integrita' memoria / HVCI)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v WasEnabledBy /t REG_DWORD /d 0 /f
REM Virtualization Based Security
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v RequirePlatformSecurityFeatures /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v Locked /t REG_DWORD /d 0 /f
REM Credential Guard
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v LsaCfgFlags /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LsaCfgFlags /t REG_DWORD /d 0 /f
REM System Guard
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SystemGuard" /v Enabled /t REG_DWORD /d 0 /f
 
echo [4/5] Imposto i servizi Hyper-V su disabilitato (cosi' non si riaccendono)...
sc config vmms start= disabled
sc config HvHost start= disabled
sc config vmcompute start= disabled
 
echo [5/5] Preparo la disattivazione firmware di VBS/LSA...
mountvol X: /s
copy "%WINDIR%\System32\SecConfig.efi" X:\EFI\Microsoft\Boot\SecConfig.efi /Y
bcdedit /create {0cb3b571-2f2e-4343-a879-d86a144d7853} /d "DebugTool" /application osloader
bcdedit /set {0cb3b571-2f2e-4343-a879-d86a144d7853} path \EFI\Microsoft\Boot\SecConfig.efi
bcdedit /set {0cb3b571-2f2e-4343-a879-d86a144d7853} device partition=X:
bcdedit /set {bootmgr} bootsequence {0cb3b571-2f2e-4343-a879-d86a144d7853}
bcdedit /set {0cb3b571-2f2e-4343-a879-d86a144d7853} loadoptions DISABLE-LSA-ISO,DISABLE-VBS
mountvol X: /d
 
echo.
echo ============================================================
echo  Riavvio tra 5 secondi.
echo  *** Al riavvio apparira' una schermata (sfondo blu) che  ***
echo  *** CHIEDE CONFERMA per disattivare VBS/Device Guard.     ***
echo  *** Premi il tasto indicato (di solito F3) per CONFERMARE.***
echo  *** Se non premi nulla, Windows annulla e non cambia nulla***
echo ============================================================
echo.
pause
shutdown /r /t 5