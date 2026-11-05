@echo off
REM ============================================================
REM RIPRISTINO: riattiva Hyper-V / VBS / Device Guard /
REM Isolamento core / Credential Guard + servizi e feature.
REM Annulla cio' che fa disabilita-vbs-virtualbox.bat
REM ESEGUIRE COME AMMINISTRATORE
REM ============================================================

echo [1/5] Riattivo hypervisor e feature Windows principali...
bcdedit /set hypervisorlaunchtype auto
dism.exe /online /enable-feature /featurename:Microsoft-Hyper-V-All /all /norestart
dism.exe /online /enable-feature /featurename:HypervisorPlatform /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /norestart

echo [2/5] Riattivo feature dipendenti (sandbox, WSL, App Guard)...
dism.exe /online /enable-feature /featurename:Containers-DisposableClientVM /norestart
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /norestart
dism.exe /online /enable-feature /featurename:Windows-Defender-ApplicationGuard /norestart
dism.exe /online /enable-feature /featurename:HostGuardian /norestart

echo [3/5] Riattivo Isolamento core / Memory Integrity / VBS / Credential Guard via registro...
REM Memory Integrity (Integrita' memoria / HVCI)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /t REG_DWORD /d 1 /f
REM Virtualization Based Security
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v RequirePlatformSecurityFeatures /t REG_DWORD /d 1 /f
REM Credential Guard
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v LsaCfgFlags /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LsaCfgFlags /t REG_DWORD /d 1 /f
REM System Guard
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SystemGuard" /v Enabled /t REG_DWORD /d 1 /f
REM Rimuovo la chiave "Locked" azzerata dallo script di disattivazione (se presente)
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v Locked /f 2>nul

echo [4/5] Rimetto i servizi Hyper-V su avvio automatico/manuale...
sc config vmms start= demand
sc config HvHost start= demand
sc config vmcompute start= demand

echo [5/5] Rimuovo la voce di boot "DebugTool" creata per il firmware...
bcdedit /deletevalue {bootmgr} bootsequence 2>nul
bcdedit /delete {0cb3b571-2f2e-4343-a879-d86a144d7853} 2>nul

echo.
echo ============================================================
echo  Ripristino completato. Riavvio tra 5 secondi.
echo  Nota: VBS/Credential Guard si riattivano al riavvio.
echo  Se avevi confermato la disattivazione firmware con F3,
echo  Windows potrebbe NON richiedere nulla al riavvio: e' normale.
echo ============================================================
echo.
timeout /t 8
shutdown /r /t 5
