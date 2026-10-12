/// All user-facing text, in English like the design. Translate here.
abstract final class Str {
  static const appName = 'Clock it';
  static const logIn = 'Log in';
  static const signIn = 'Sign in';

  // Account sheet. "Log in" opens an existing account, "Sign in" creates one.
  static const logInTitle = 'Welcome back';
  static const signUpTitle = 'Create your account';
  static const signUpHelp = 'Your hours are saved to your account, so you can see them on any phone.';
  static const email = 'Email';
  static const password = 'Password';
  static const passwordHint = 'At least 6 characters';
  static const createAccount = 'Create account';
  static const forgotPassword = 'Forgot your password?';
  static const resetSent = 'We sent you an email to choose a new password.';
  static const noAccount = 'New here? Create an account';
  static const haveAccount = 'Already have an account? Log in';
  static const authInvalidEmail = 'That email doesn’t look right.';
  static const authWrongCredentials = 'Wrong email or password.';
  static const authEmailInUse = 'There is already an account with that email. Log in instead.';
  static const authWeakPassword = 'Use at least 6 characters.';
  static const authDisabled = 'This account has been disabled.';
  static const authTooMany = 'Too many tries. Wait a moment and try again.';
  static const authOffline = 'No connection. Check your internet and try again.';
  static const authGeneric = 'Something went wrong. Try again.';
  static const authMissing = 'Enter your email and password.';

  static const markEntry = 'Mark entry';
  static const markExit = 'Mark exit';
  static String inSince(String time, String elapsed) => 'In since $time · $elapsed';

  static const hoursLeft = 'Hours left to do:';
  static const goalReached = 'Goal reached!';
  static String ofGoal(String done, String goal) => '$done of $goal';

  static const actualGoal = 'Actual goal';
  static const monFri = 'Mon-Fri';
  static const everyday = 'Everyday';
  static String daysLeft(int weekdays, int all) => '$weekdays weekdays · $all days left';

  static String monthTotal(String total) => '$total this month';
  static String daysWorked(int days, String avg) =>
      days == 0 ? 'No hours yet' : '$days ${days == 1 ? 'day' : 'days'} · avg $avg';

  static const monthsShort = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];
  static const monthsLong = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const weekdaysShort = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
  static const weekdaysLong = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  // Day sheet
  static const hoursThatDay = 'Hours worked';
  static const durationHint = 'e.g. 5h30m';
  static const formats = 'Formats: 5h, 5h30m, 45m, 5:30 or 5.5';
  static const invalidDuration = 'Didn’t get that. Try 5h30m.';
  static const sessions = 'Clock-ins';
  static const manual = '+ added by hand';
  static String runningSince(String time) =>
      'Session running since $time — it is added when you mark exit.';
  static const editReplacesSessions = 'Saving a new total replaces the clock-ins with it.';
  static const delete = 'Delete';
  static const save = 'Save';
  static const cancel = 'Cancel';

  // Goal sheet
  static const monthlyGoal = 'Monthly goal';
  static const goalHint = 'Hours per month';
  static const invalidGoal = 'Enter a number of hours above 0.';

  // Menu
  static const today = 'Go to today';
  static const changeGoal = 'Change goal';
  static const backup = 'Backup';
  static const logOut = 'Log out';
  static const deleteAccount = 'Delete account';
  static const deleteAccountHelp =
      'This deletes your account and all its hours for good. Enter your password to confirm.';
  static const logOutConfirm = 'Log out of this phone? Your hours stay saved in your account.';

  // Backup sheet
  static const backupHelp =
      'Save a copy of your hours as a file, or restore one. Backups from the web version work too.';
  static const exportFile = 'Export file';
  static const copyJson = 'Copy as text';
  static const importFile = 'Import file';
  static const pasteJson = 'Paste text';
  static const copied = 'Backup copied';
  static const imported = 'Backup restored';
  static const importFailed = 'That isn’t a valid Clock it backup.';
  static const importConfirm = 'This replaces all the hours in your account. Continue?';
  static const replace = 'Replace';
}
