# SetPoint

Aplicación móvil en Flutter para la gestión de voleibol. Reúne en una sola app tres módulos que se mantienen independientes entre sí:

- **Partidos:** marcador en vivo sincronizado en tiempo real entre varios dispositivos.
- **Estadísticas:** análisis punto a punto de cada partido y de cada set.
- **Entrenamiento:** agenda semanal por persona y ejercicios con temporizador de descanso.

En un partido real, una persona hace de anotadora oficial y el resto de los dispositivos ve el marcador al instante.

## Funciones

### Partidos
- Lista de partidos agrupados por torneo, con filtros: todos, por empezar, en vivo y finalizados.
- Marcador en vivo: puntos por tipo de acción (ataque, bloqueo, ace, error del rival), cambio de saque y rotación automática.
- Sets a 25 puntos y el quinto a 15, con diferencia de 2. El partido termina cuando un equipo gana 3 sets.
- Cronómetro por set y duración total del partido.
- **Deshacer** el último punto (hasta 50 pasos), también entre sets.
- Aviso de punto de set y de punto de partido.
- Alineación de cada equipo con su rotación.
- Funciona sin conexión: los cambios se guardan en el teléfono y se sincronizan al reconectar.

### Estadísticas
- Gráfica de momentum punto a punto con los colores de cada equipo.
- Comparativa de puntos de ataque, bloqueo, aces y errores no forzados.
- Rachas de puntos consecutivos.
- Filtro por partido completo o por set. Solo aparecen los sets que se jugaron.

### Entrenamiento
- **Agenda:** rutina semanal de cada persona (entrenamiento, físico, psicólogo, nutrición, fisioterapia, partido, estudio, descanso), con indicadores «Ahora» y «Siguiente». Se puede cambiar de persona y agregar, editar o borrar actividades.
- **Ejercicios:** lista de ejercicios del día por categoría, progreso de la sesión y temporizador de descanso entre series.
- Todo se guarda en el teléfono.

### Administración
Al tocar el logo **SetPoint** de la pantalla Partidos se abre la administración de partidos:
- Crear partidos, eligiendo equipos y torneo existentes o dándolos de alta en el mismo formulario (nombre, siglas, color y jugadores).
- Borrar partidos.
- Restaurar los datos de ejemplo.

## Tecnologías

- **Flutter** (Dart `^3.13.5`), con `material_ui` para los componentes de Material Design.
- **Cloud Firestore** para los partidos, equipos y torneos en tiempo real.
- **shared_preferences** para los datos locales de Entrenamiento.
- Estado con herramientas del propio SDK (`ChangeNotifier`, `InheritedWidget`, `StreamBuilder`), sin paquetes de estado ni generadores de código.

## Puesta en marcha

### Requisitos
- Flutter SDK (probado con Flutter 3.50).
- Un dispositivo Android o un emulador.
- Un proyecto de Firebase con Cloud Firestore activado.

### 1. Instalar dependencias
```bash
flutter pub get
```

### 2. Configurar Firebase
`lib/firebase_options.dart` no se incluye en el repositorio. Para generarlo:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

También puedes copiar `lib/firebase_options.dart.example` a `lib/firebase_options.dart` y rellenar los valores de tu proyecto.

Si la configuración falta o es incorrecta, la app no se cierra: muestra una pantalla con el error y los pasos para corregirlo.

### 3. Ejecutar
```bash
flutter run              # modo desarrollo
flutter run --release    # rendimiento real, como en cancha
```

Con la base de datos vacía, la app ofrece **«Crear partido de ejemplo»** para cargar dos partidos de muestra.

### Compilar el APK
```bash
flutter build apk --release
```
El archivo queda en `build/app/outputs/flutter-apk/app-release.apk`.

### Color de marca
La app es azul por defecto. Para compilarla con otro color de marca, pásalo en hexadecimal con `SP_BRAND`:

```bash
flutter build apk --release --dart-define=SP_BRAND=129A55
flutter run --dart-define=SP_BRAND=129A55   # para probarlo antes
```

El resto de los tonos se calcula solo: barra superior, tinte del cristal, variante para modo oscuro y color del texto sobre la marca. Si el color es muy claro (p. ej. amarillo), en modo claro se oscurece lo justo para que se lea sobre blanco. Conviene evitar el rojo puro, porque se confunde con el indicador «en vivo».

## Estructura de datos en Firestore

| Colección | Contenido |
| --- | --- |
| `tournaments/{id}` | `name`, `category`, `season` |
| `teams/{id}` | `name`, `shortName`, `color` (`#RRGGBB`), `players[]` (`dorsal`, `name`, `role`) |
| `matches/{id}` | Referencias `tournamentId`, `homeTeamId`, `awayTeamId`; datos del partido (`stage`, `venue`, `startTime`) y estado de juego (`currentSet`, `localPoints`, `visitPoints`, `sets[]`, `events[]`, alineaciones, `rev`) |

La lectura de los documentos es tolerante: se pueden editar a mano desde la consola de Firebase y los campos que faltan toman valores por defecto.

## Estructura del proyecto

```
lib/
├── core/          Tema (modo claro y oscuro) y widgets compartidos (cristal, reloj en vivo…)
├── data/          Repositorio de datos: Firestore y uno en memoria para pruebas
├── models/        Modelo del partido y reglas del juego
└── features/
    ├── home/        Navegación principal con barra flotante
    ├── matches/     Lista, detalle, cabecera del marcador y administración de partidos
    ├── scoreboard/  Pestaña «Detalles»: registro de puntos y marcador por sets
    ├── statistics/  Pestaña «Estadísticas»
    ├── lineup/      Pestaña «Alineación»
    ├── training/    Agenda y ejercicios (independiente del resto)
    └── setup/       Pantalla de ayuda si falta la configuración de Firebase
```

La interfaz solo conoce la interfaz `MatchRepository`, así que la fuente de datos se puede sustituir. Las pruebas usan `InMemoryMatchRepository` y no necesitan Firebase.

## Pruebas y calidad

```bash
flutter analyze
flutter test
```

## Mejoras pendientes

La lista de mejoras planeadas y su prioridad está en [`MEJORAS.md`](MEJORAS.md).
