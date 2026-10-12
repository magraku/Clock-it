# Clock it

App en Flutter (iPhone y Android) para contar las horas de SFP. Es la versión nativa de
`reference/horas-sfp.html`, con el diseño de `reference/Clock-it.vectorcraft`.

| Inicio | Pantalla principal | Editar un día |
|---|---|---|
| ![](docs/screenshots/welcome.png) | ![](docs/screenshots/home_iphone.png) | ![](docs/screenshots/day_sheet.png) |

## Cómo correrla

```bash
flutter pub get
flutter run            # con un iPhone/simulador o un Android conectado
flutter test           # pruebas de la lógica y del flujo principal
```

Si cambias el logo o el splash:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Cómo se usa

- **Mark entry / Mark exit**: botón grande arriba. Mientras hay una entrada abierta muestra la hora
  de entrada y el cronómetro en vivo. Puedes marcar varias veces al día.
- **Hours left to do**: lo que falta para la meta, con barra de progreso (`36h de 140h`).
- **Calendario**: cada día muestra sus horas; el naranja es más intenso cuanto más trabajaste y
  hoy está en rosa. Toca un día para ver sus entradas/salidas, cambiar el total
  (`5h`, `5h30m`, `45m`, `5:30`, `5.5`) o borrarlo.
- **Cambiar de mes**: flechas ‹ › o deslizar el calendario. Tocar el nombre del mes vuelve a hoy.
- **Tarjeta verde**: meta mensual y horas por día necesarias (lunes a viernes / todos los días,
  contando hoy). Tócala para cambiar la meta.
- **Botón •••**: ir a hoy, cambiar la meta y respaldo (exportar/importar JSON como archivo o como
  texto). Los respaldos de la versión web también se pueden importar.

## Estructura

```
lib/
  models/hours_data.dart      datos (mismo JSON que la versión web)
  logic/time_math.dart        cálculos: totales, lo que falta, horas/día, formatos
  data/hours_store.dart       almacenamiento (local hoy; Firebase después)
  state/app_state.dart        estado de la app y cronómetro
  ui/screens/                 splash, bienvenida y pantalla principal
  ui/widgets/calendar_sheet   el calendario de pared
  ui/sheets.dart              hojas: día, meta, menú y respaldo
  ui/theme.dart               colores y tipografías sacados del .vectorcraft
  ui/strings.dart             todos los textos (para traducir)
assets/
  images/logo.svg             logo vectorial, exportado del .vectorcraft
  images/bg_*.jpg             fondos en 1290 px de ancho
  images/calendar_paper.png   hoja del calendario con las argollas
  fonts/                      Source Sans 3, Anton, Outfit (licencia OFL)
```

## Firebase (siguiente paso)

`HoursStore` es una interfaz: basta con crear un `FirebaseHoursStore` que la implemente y usar
`updatedAt` (el campo `ts`) para quedarse con la versión más reciente, como en la versión web.
Los botones **Log in / Sign in** ya están en `WelcomeScreen._continue` (marcado con `TODO(firebase)`);
por ahora los dos solo abren la app y los datos quedan en el teléfono.
