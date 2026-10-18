@echo off
setlocal
where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter nao foi encontrado no PATH.
  echo Instale o Flutter SDK e adicione flutter\bin ao PATH.
  pause
  exit /b 1
)
if not exist pubspec.yaml (
  echo Execute este arquivo dentro da pasta MOVVA que contem pubspec.yaml.
  pause
  exit /b 1
)
if not exist android (
  echo Gerando estrutura Android...
  flutter create --platforms=android --org com.movva .
  if errorlevel 1 goto erro
)
echo Instalando dependencias...
flutter pub get
if errorlevel 1 goto erro
echo.
echo Dispositivos encontrados:
flutter devices
echo.
echo Para executar no celular conectado, rode: flutter run
pause
exit /b 0
:erro
echo Ocorreu um erro. Confira Flutter Doctor e o README_WINDOWS.md.
pause
exit /b 1
