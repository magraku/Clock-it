import 'dart:ui' show Locale;

/// All user-facing text, in English and Spanish. The phone's language picks
/// one at launch ([useLocale]); anything that isn't Spanish gets English.
abstract final class Str {
  static bool _es = false;

  /// True when the app speaks Spanish.
  static bool get spanish => _es;

  static void useLocale(Locale locale) => _es = locale.languageCode == 'es';

  /// For tests.
  static void useSpanish(bool on) => _es = on;

  static String _t(String en, String es) => _es ? es : en;

  static const appName = 'Clock it';
  static String get logIn => _t('Log in', 'Iniciar sesión');
  static String get signUp => _t('Sign up', 'Crear cuenta');

  // Account sheet. "Log in" opens an existing account, "Sign up" creates one.
  static String get logInTitle => _t('Welcome back', 'Hola de nuevo');
  static String get signUpTitle => _t('Create your account', 'Crea tu cuenta');
  static String get signUpHelp => _t(
        'Your hours are saved to your account, so you can see them on any phone.',
        'Tus horas se guardan en tu cuenta, así las ves en cualquier teléfono.',
      );
  static String get email => _t('Email', 'Correo');
  static String get password => _t('Password', 'Contraseña');
  static String get passwordHint => _t('At least 6 characters', 'Mínimo 6 caracteres');
  static String get showPassword => _t('Show password', 'Mostrar contraseña');
  static String get hidePassword => _t('Hide password', 'Ocultar contraseña');
  static String get createAccount => _t('Create account', 'Crear cuenta');
  static String get forgotPassword => _t('Forgot your password?', '¿Olvidaste tu contraseña?');
  // Firebase doesn't reveal whether an email has an account, so this can't either.
  static String get resetSent => _t(
        'If there is an account with that email, we sent it a link to choose a new password. '
            'It can take a few minutes; check your spam folder too.',
        'Si hay una cuenta con ese correo, le enviamos un enlace para elegir una contraseña nueva. '
            'Puede tardar unos minutos; revisa también la carpeta de spam.',
      );
  static String get demoReset => _t(
        'This is the web demo: no emails are sent and passwords aren’t stored. '
            'Log in with your email and any password of 6 or more characters.',
        'Esta es la demo web: no se envían correos ni se guardan contraseñas. '
            'Entra con tu correo y cualquier contraseña de 6 caracteres o más.',
      );
  static String get noAccount => _t('New here? Create an account', '¿Eres nueva/o? Crea una cuenta');
  static String get haveAccount => _t('Already have an account? Log in', '¿Ya tienes cuenta? Inicia sesión');
  static String get authInvalidEmail => _t('That email doesn’t look right. Check it and try again.',
      'Ese correo no parece correcto. Revísalo e inténtalo de nuevo.');
  static String get authWrongCredentials =>
      _t('Wrong email or password. Check them and try again.', 'Correo o contraseña incorrectos. Revísalos e inténtalo de nuevo.');
  static String get authEmailInUse =>
      _t('There is already an account with that email. Log in instead.', 'Ya hay una cuenta con ese correo. Inicia sesión.');
  static String get authWeakPassword => _t('Use at least 6 characters.', 'Usa al menos 6 caracteres.');
  static String get authDisabled => _t('This account has been disabled.', 'Esta cuenta está desactivada.');
  static String get authTooMany =>
      _t('Too many tries. Wait a moment and try again.', 'Demasiados intentos. Espera un momento y vuelve a intentarlo.');
  static String get authOffline =>
      _t('No connection. Check your internet and try again.', 'Sin conexión. Revisa tu internet y vuelve a intentarlo.');
  static String get authGeneric => _t('Something went wrong. Try again.', 'Algo salió mal. Inténtalo de nuevo.');
  static String get authMissing => _t('Enter your email and password.', 'Escribe tu correo y tu contraseña.');

  // Bottom bar
  static String get tabGoals => _t('Goals', 'Metas');
  static String get tabHome => _t('Home', 'Inicio');
  static String get tabProfile => _t('Profile', 'Perfil');

  // Goals screen
  static String get createGoal => _t('+ Create new goal', '+ Crear nueva meta');
  static String get onHome => _t('On Home', 'En Inicio');

  // Goal screen
  static String get timer => _t('Timer:', 'Cronómetro:');
  static String minutesChip(int m) => '${m}min';
  static String minutesLong(int m) => _t('$m minutes', '$m minutos');
  static String get start => _t('Start', 'Empezar');
  static String get stop => _t('Stop', 'Parar');
  static String get closeTimer => _t('Back to the calendar', 'Volver al calendario');
  static String hourglassStyle(String name) => _t('$name hourglass', 'Reloj de arena $name');

  // Wallpapers: the focus screen's background, also saved for the lock screen.
  static String get wallpaper => _t('Wallpaper', 'Fondo de pantalla');
  static String get wallpaperHelp => _t(
        'Shown behind your focus timers. Save it to set it on your lock screen too.',
        'Se ve detrás de tus cronómetros. Guárdalo para ponerlo también en tu pantalla bloqueada.',
      );
  static List<String> get wallpaperNames => [
        _t('Original', 'Original'),
        _t('Paint drop', 'Gota de pintura'),
        _t('Dusk', 'Anochecer'),
        _t('Meadow', 'Pradera'),
        _t('Pattern', 'Patrón'),
      ];
  static String wallpaperOption(String name) => _t('$name wallpaper', 'Fondo $name');
  static String get saveWallpaper => _t('Save to phone', 'Guardar en el teléfono');
  static List<String> get hourglassNames =>
      _es ? const ['clásico', 'de cristal', 'de líneas', 'de granos'] : const ['Classic', 'Glass', 'Line', 'Grains'];
  static String readyToStart(int m) =>
      _t('Hourglass ready for $m minutes. Press Start.', 'Reloj de arena listo para $m minutos. Pulsa Empezar.');
  static String get moreOptions => _t('More options', 'Más opciones');
  static String get prevMonth => _t('Previous month', 'Mes anterior');
  static String get nextMonth => _t('Next month', 'Mes siguiente');
  static String dayHours(String day, String hours) => hours.isEmpty ? day : '$day, $hours';
  static String get timerDoneTitle => _t('Time’s up', 'Se acabó el tiempo');
  static String timerDoneBody(String goal, String length) =>
      _t('$length of focus on $goal. Nice work.', '$length de concentración en $goal. Buen trabajo.');
  static String timerSemantics(String left) => _t('Hourglass, $left left', 'Reloj de arena, quedan $left');
  static String get focusTimeLeft => _t('Focus time left', 'Tiempo de concentración restante');

  // Goal editor
  static String get newGoal => _t('New goal', 'Nueva meta');
  static String get editGoal => _t('Edit goal', 'Editar meta');
  static String get goalName => _t('Name', 'Nombre');
  static String get goalNameHint => _t('e.g. Study hours', 'p. ej. Horas de estudio');
  static String get goalNameMissing => _t('Give your goal a name.', 'Ponle un nombre a tu meta.');
  static String get color => _t('Color', 'Color');
  static List<String> get colorNames =>
      _es ? const ['Verde', 'Naranja', 'Rosa', 'Amarillo'] : const ['Green', 'Orange', 'Pink', 'Yellow'];
  static String get monthlyHours => _t('Monthly goal (hours)', 'Meta del mes (horas)');
  static String get showOnHome => _t('Show on Home', 'Mostrar en Inicio');
  static String get create => _t('Create', 'Crear');
  static String get deleteGoal => _t('Delete goal', 'Borrar meta');
  static String deleteGoalConfirm(String name) =>
      _t('Delete “$name” and all its hours?', '¿Borrar “$name” y todas sus horas?');
  static String get lastGoal =>
      _t('This is your only goal, so it can’t be deleted.', 'Es tu única meta, así que no se puede borrar.');

  // Profile
  static String get signedInAs => _t('Signed in as', 'Sesión iniciada como');
  static String goalCount(int n) => _es ? '$n ${n == 1 ? 'meta' : 'metas'}' : '$n ${n == 1 ? 'goal' : 'goals'}';

  static String get markEntry => _t('Mark entry', 'Marcar entrada');
  static String get markExit => _t('Mark exit', 'Marcar salida');
  static String inSince(String time, String elapsed) =>
      _t('Entered at $time · $elapsed', 'Entraste a las $time · $elapsed');
  static String todaySoFar(String hours) => _t('Today: $hours', 'Hoy: $hours');

  // History (from Profile)
  static String get history => _t('History', 'Historial');
  static String get back => _t('Back', 'Volver');
  static String get historyEmpty => _t('No hours this month yet.', 'Aún no hay horas este mes.');
  static String get now => _t('now', 'ahora');
  static String byHand(String hours) => _t('+ $hours added by hand', '+ $hours añadidas a mano');
  static String session(String from, String to) => _t('$from to $to', 'de $from a $to');
  static String goalOption(String name) => _t('Show $name', 'Ver $name');

  static String get hoursLeft => _t('Hours left to do:', 'Horas que faltan:');
  static String hoursLeftFor(String goal) => _t('$goal · hours left to do:', '$goal · horas que faltan:');
  static String get goalReached => _t('Goal reached', 'Meta cumplida');
  static String ofGoal(String done, String goal) => _t('$done of $goal', '$done de $goal');

  static String get actualGoal => _t('Actual goal', 'Meta');
  static String get monFri => _t('Mon-Fri', 'Lun-Vie');
  static String get everyday => _t('Everyday', 'Diario');
  static String daysLeft(int weekdays, int all) => _t(
        '$weekdays weekdays · $all days left',
        '$weekdays días hábiles · quedan $all días',
      );

  static String monthTotal(String total) => _t('$total this month', '$total este mes');
  static String daysWorked(int days, String avg) => _es
      ? (days == 0 ? 'Aún sin horas' : '$days ${days == 1 ? 'día' : 'días'} · promedio $avg')
      : (days == 0 ? 'No hours yet' : '$days ${days == 1 ? 'day' : 'days'} · avg $avg');

  static List<String> get monthsShort => _es
      ? const ['ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN', 'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC']
      : const ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
  static List<String> get monthsLong => _es
      ? const [
          'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
          'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
        ]
      : const [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December',
        ];
  static List<String> get weekdaysShort =>
      _es ? const ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sá', 'Do'] : const ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
  static List<String> get weekdaysLong => _es
      ? const ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo']
      : const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  /// "October 2026" / "octubre de 2026".
  static String monthYear(int year, int month) =>
      _es ? '${monthsLong[month - 1]} de $year' : '${monthsLong[month - 1]} $year';

  /// "Thursday, 1 October" / "jueves 1 de octubre".
  static String fullDate(DateTime d) => _es
      ? '${weekdaysLong[d.weekday - 1]} ${d.day} de ${monthsLong[d.month - 1]}'
      : '${weekdaysLong[d.weekday - 1]}, ${d.day} ${monthsLong[d.month - 1]}';

  // Day sheet
  static String get hoursThatDay => _t('Hours worked', 'Horas trabajadas');
  static String get durationHint => _t('e.g. 5h30m', 'p. ej. 5h30m');
  static String get formats => _t('Formats: 5h, 5h30m, 45m, 5:30 or 5.5', 'Formatos: 5h, 5h30m, 45m, 5:30 o 5.5');
  static String get invalidDuration => _t('Didn’t get that. Try 5h30m.', 'No lo entendí. Prueba con 5h30m.');
  static String get sessions => _t('Clock-ins', 'Entradas');
  static String get manual => _t('+ added by hand', '+ añadido a mano');
  static String runningSince(String time) => _t(
        'Session running since $time — it is added when you mark exit.',
        'Sesión en curso desde las $time: se suma al marcar la salida.',
      );
  static String get editReplacesSessions => _t(
        'Saving a new total replaces the clock-ins with it.',
        'Guardar un total nuevo reemplaza las entradas por ese total.',
      );
  static String get delete => _t('Delete', 'Borrar');
  static String get save => _t('Save', 'Guardar');
  static String get cancel => _t('Cancel', 'Cancelar');

  // Goal sheet
  static String get monthlyGoal => _t('Monthly goal', 'Meta del mes');
  static String get goalHint => _t('Hours per month', 'Horas al mes');
  static String get invalidGoal => _t('Enter a number of hours above 0.', 'Escribe un número de horas mayor que 0.');

  // Menu
  static String get today => _t('Go to today', 'Ir a hoy');
  static String get changeGoal => _t('Change goal', 'Cambiar meta');
  static String get backup => _t('Backup', 'Respaldo');
  static String get logOut => _t('Log out', 'Cerrar sesión');
  static String get deleteAccount => _t('Delete account', 'Borrar cuenta');
  static String get deleteAccountHelp => _t(
        'This deletes your account and all its hours for good. Enter your password to confirm.',
        'Esto borra tu cuenta y todas sus horas para siempre. Escribe tu contraseña para confirmar.',
      );
  static String get logOutConfirm => _t(
        'Log out of this phone? Your hours stay saved in your account.',
        '¿Cerrar sesión en este teléfono? Tus horas siguen guardadas en tu cuenta.',
      );

  // Backup sheet
  static String get backupHelp => _t(
        'Save a copy of your hours as a file, or restore one. Backups from the web version work too.',
        'Guarda una copia de tus horas en un archivo o restaura una. También sirven los respaldos de la versión web.',
      );
  static String get exportFile => _t('Export file', 'Exportar archivo');
  static String get copyJson => _t('Copy as text', 'Copiar como texto');
  static String get importFile => _t('Import file', 'Importar archivo');
  static String get pasteJson => _t('Paste text', 'Pegar texto');
  static String get copied => _t('Backup copied', 'Respaldo copiado');
  static String get imported => _t('Backup restored', 'Respaldo restaurado');
  static String get importFailed =>
      _t('That isn’t a valid Clock it backup. Check the file and try again.', 'Eso no es un respaldo válido de Clock it. Revisa el archivo e inténtalo de nuevo.');
  static String get importConfirm => _t(
        'This replaces your goals and hours with the backup (a web-version backup replaces only Home’s hours). Continue?',
        'Esto reemplaza tus metas y horas por las del respaldo (un respaldo de la versión web solo reemplaza las horas de Inicio). ¿Continuar?',
      );
  static String get replace => _t('Replace', 'Reemplazar');
}
