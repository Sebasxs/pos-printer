@echo off
setlocal EnableDelayedExpansion
title SmartPOS Agent - Asistente de Instalacion

:: ==========================================
:: CONFIGURACION
:: ==========================================
set "NOMBRE_SERVICIO=SmartPOS Printer Agent"
set "RUTA_INSTALACION=C:\SmartPOS-agent"
set "FUENTE=%~dp0"
:: ==========================================

:: 1. VERIFICAR PERMISOS DE ADMINISTRADOR
net session >nul 2>&1
if %errorLevel% neq 0 (
    color 4F
    echo.
    echo [ERROR CRITICO] SE REQUIEREN PERMISOS DE ADMINISTRADOR.
    echo.
    echo Por favor, haz CLICK DERECHO sobre este archivo
    echo y selecciona "EJECUTAR COMO ADMINISTRADOR".
    echo.
    pause
    exit
)

cls
color 1F
echo ========================================================
echo      ASISTENTE DE INSTALACION SMARTPOS AGENT
echo ========================================================
echo.
echo  Ruta de instalacion: %RUTA_INSTALACION%
echo.

:: 2. VERIFICAR SI EL SERVICIO YA EXISTE
sc query "%NOMBRE_SERVICIO%" >nul 2>&1
if %errorLevel% equ 0 (
    set "MODO=ACTUALIZACION"
    color 1F
    echo  [!] El servicio ya existe. Modo detectado: ACTUALIZACION.
) else (
    set "MODO=INSTALACION"
    color 2F
    echo  [*] El servicio no existe. Modo detectado: INSTALACION LIMPIA.
)
echo.
echo  Presiona cualquier tecla para comenzar...
pause >nul

:: 3. DETENER SERVICIO SI ESTA CORRIENDO
if "%MODO%"=="ACTUALIZACION" (
    echo.
    echo  [1/5] Deteniendo servicio actual...
    net stop "%NOMBRE_SERVICIO%" >nul 2>&1
    timeout /t 3 /nobreak >nul
)

:: 4. PREPARAR CARPETA
echo.
echo  [2/5] Preparando carpeta de destino...
if not exist "%RUTA_INSTALACION%" mkdir "%RUTA_INSTALACION%"

:: 5. COPIAR ARCHIVOS (Robocopy es mas robusto que xcopy)
echo.
echo  [3/5] Copiando archivos al sistema...

:: Copiamos archivos criticos ignorando el propio instalador
robocopy "%FUENTE%." "%RUTA_INSTALACION%" *.* /E /XD node_modules /XF installer.bat /IS /IT >nul

:: Copiar node_modules solo si existen en la fuente (para instalación offline)
if exist "%FUENTE%node_modules" (
    echo        - Copiando librerias (esto puede tardar)...
    robocopy "%FUENTE%node_modules" "%RUTA_INSTALACION%\node_modules" /E >nul
)

if %errorLevel% geq 8 (
    color 4F
    echo [ERROR] Fallo al copiar archivos. Verifica permisos.
    pause
    exit
)

:: 6. OCULTAR ARCHIVOS SENSIBLES (Seguridad nivel basico)
echo.
echo  [4/5] Aplicando seguridad basica...
if exist "%RUTA_INSTALACION%\.env" attrib +h +r "%RUTA_INSTALACION%\.env"
if exist "%RUTA_INSTALACION%\*.json" attrib +h +r "%RUTA_INSTALACION%\*.json"

:: 7. LOGICA DE INSTALACION / REINICIO
echo.
if "%MODO%"=="INSTALACION" (
    echo  [5/5] Registrando nuevo servicio en Windows...
    cd /d "%RUTA_INSTALACION%"
    
    :: Instalamos dependencias si no se copiaron
    if not exist "node_modules" (
        echo        - Instalando dependencias npm (requiere internet)...
        call npm install --production
    )
    
    node install_service.js
) else (
    echo  [5/5] Reiniciando servicio actualizado...
    cd /d "%RUTA_INSTALACION%"
    
    :: Si es actualizacion, a veces necesitamos actualizar dependencias
    if not exist "node_modules" (
        call npm install --production
    )
    
    net start "%NOMBRE_SERVICIO%"
)

echo.
echo ========================================================
color 2F
echo      PROCESO COMPLETADO EXITOSAMENTE
echo ========================================================
echo.
if "%MODO%"=="INSTALACION" echo  El servicio se instalara e iniciara automaticamente ahora.
if "%MODO%"=="ACTUALIZACION" echo  El servicio ha sido actualizado y reiniciado.
echo.
pause