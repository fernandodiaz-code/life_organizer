# Guia de lectura del codigo - Sprint 1

Este documento explica la base tecnica actual de life_organizer para estudiar el codigo, entender el flujo de ejecucion y aprender a depurar errores.

## 1. Estructura general

El proyecto ahora es un monorepo. Un solo repositorio contiene varios paquetes relacionados:

~~~text
packages/
  core/
  life_organizer/
  wetface/
~~~

- packages/life_organizer: aplicacion Flutter principal.
- packages/core: codigo compartido de configuracion y clientes base.
- packages/wetface: modulo separado para la alarma WetFace.

La idea es que WetFace pueda crecer sin mezclar todo dentro de la app principal.

## 2. Workspace y Melos

El pubspec.yaml de la raiz define el workspace con los tres paquetes. Eso permite ejecutar comandos comunes desde la raiz.

Comandos utiles:

~~~bash
dart pub get
dart run melos exec --concurrency 1 -- "dart analyze ."
dart run melos exec --dir-exists=test --concurrency 1 -- "flutter test"
~~~

## 3. Arranque de la app

Archivo principal:

~~~text
packages/life_organizer/lib/main.dart
~~~

Flujo general:

- main() inicializa Flutter.
- Carga formato de fechas en espanol con initializeDateFormatting.
- Si existen credenciales locales de Supabase, inicializa Supabase.
- Configura estilo de barra de estado.
- Ejecuta runApp(const LifeOrganizerApp()).

Punto importante de depuracion: la app no debe llamar Supabase.instance si Supabase no fue inicializado.

Error que se vio en pantalla roja:

~~~text
You must initialize the supabase instance before calling Supabase.instance
~~~

Por eso AuthGate revisa primero si existen SUPABASE_URL y SUPABASE_ANON_KEY. Si no existen, muestra LoginScreen sin activar Supabase.

## 4. Configuracion central

Archivo:

~~~text
packages/life_organizer/lib/core/constants.dart
~~~

Este archivo expone constantes de la app. Para credenciales no guarda valores directos, sino que lee desde life_core usando CoreEnvironment.

## 5. Paquete core

Archivos principales:

~~~text
packages/core/lib/src/core_environment.dart
packages/core/lib/src/cloudflare_client.dart
~~~

CoreEnvironment lee variables pasadas al compilar o ejecutar Flutter:

- SUPABASE_URL
- SUPABASE_ANON_KEY
- N8N_WEBHOOK_URL
- CLOUDFLARE_BASE_URL

CloudflareClient es una base para llamar a Cloudflare Worker con JSON. La direccion arquitectonica es que Flutter no guarde claves sensibles y Cloudflare actue como capa intermedia.

## 6. Login y autenticacion

Archivo:

~~~text
packages/life_organizer/lib/screens/auth/login_screen.dart
~~~

Responsabilidades:

- Mostrar formulario de correo y contrasena.
- Alternar entre iniciar sesion y crear cuenta.
- Llamar a Supabase Auth solo si authEnabled es true.

Punto clave para evitar el crash:

~~~dart
if (!widget.authEnabled) {
  _showSnack('Configura Supabase con --dart-define para iniciar sesion.');
  return;
}
~~~

Esto permite que la app abra sin romper aunque no existan credenciales locales.

## 7. Navegacion principal

Archivo:

~~~text
packages/life_organizer/lib/navigation/main_shell.dart
~~~

MainShell mantiene las pantallas principales en un IndexedStack. Pantallas actuales:

- Dashboard
- Tareas
- Horario
- Proyectos
- Jarvis
- WetFace

WetFace se integra como una pestana mas usando WetFaceAlarmScreen.

## 8. Servicios de datos

Carpeta:

~~~text
packages/life_organizer/lib/services/
~~~

Ejemplos: tareas_service.dart, horario_service.dart, proyectos_service.dart y deadlines_service.dart.

Estos archivos concentran consultas y escrituras. En la version actual aun hablan con Supabase desde Flutter. En Sprint 2 conviene migrar operaciones sensibles a Cloudflare.

Para depurar servicios:

- Revisar que el usuario este autenticado.
- Revisar el nombre de tabla.
- Revisar los campos esperados por el modelo.
- Revisar valores nulos y tipos.
- Revisar permisos/RLS en Supabase.

Patron comun:

~~~dart
final data = await _db.from('tareas').select();
return (data as List<dynamic>)
    .map((j) => Tarea.fromJson(j as Map<String, dynamic>))
    .toList();
~~~

Lectura del patron:

- from('tareas') selecciona tabla.
- select() pide filas.
- data as List<dynamic> interpreta el resultado como lista.
- Tarea.fromJson convierte JSON a modelo Dart.

## 9. Modelos

Carpeta:

~~~text
packages/life_organizer/lib/models/
~~~

Los modelos representan datos de negocio: Tarea, Proyecto, HorarioItem, DeadlineItem y ChatMessage.

Cuando ocurre un error de datos, revisar si el campo existe en la base, si puede venir null, si el tipo coincide y si fromJson parsea correctamente.

## 10. Modulo WetFace

Carpeta:

~~~text
packages/wetface/
~~~

Archivos principales:

- lib/src/wetface_alarm.dart
- lib/src/wetface_alarm_screen.dart
- lib/src/wetface_validation_service.dart
- test/wetface_validation_service_test.dart

WetFaceAlarm es el modelo simple de alarma. WetFaceAlarmScreen muestra la pantalla del modulo. WetFaceValidationService contiene la validacion mock del Sprint 1.

En Sprint 1 validateMock devuelve WetFaceValidationResult.approved. En Sprint 2 deberia evolucionar para llamar a Cloudflare/Gemini.

## 11. Tests

Tests actuales:

~~~text
packages/life_organizer/test/app_constants_test.dart
packages/wetface/test/wetface_validation_service_test.dart
~~~

Comando recomendado:

~~~bash
dart run melos exec --dir-exists=test --concurrency 1 -- "flutter test"
~~~

## 12. Como depurar errores comunes

Pantalla roja de Flutter:

- Leer la primera linea util del error.
- Buscar el archivo y linea mencionados.
- Identificar si es inicializacion, tipo de dato, null-safety o dependencia externa.

Errores de analyzer:

~~~bash
dart analyze .
~~~

Si aparece unnecessary_cast, Dart ya conoce el tipo y el cast sobra.

Errores al cambiar de rama:

~~~bash
git status -sb
~~~

Si hay cambios locales, usar git stash antes de cambiar rama.

## 13. Estado final del Sprint 1

El Sprint 1 deja monorepo funcionando, app principal migrada, modulo WetFace separado, pantalla WetFace integrada, validacion mock, base Cloudflare preparada, analyzer y tests pasando.

Siguiente foco tecnico:

- migrar servicios de datos hacia Cloudflare;
- implementar alarma real;
- implementar captura/selfie real;
- conectar validacion con Gemini via Cloudflare.
