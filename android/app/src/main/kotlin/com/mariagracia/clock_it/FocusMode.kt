package com.mariagracia.clock_it

import android.app.AlarmManager
import android.app.AutomaticZenRule
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.service.notification.Condition
import android.service.notification.ConditionProviderService

/** Owns one automatic rule, never the user's manual Do Not Disturb setting. */
object FocusMode {
    private const val STORE = "clockit_focus"
    private val conditionId = Uri.parse("condition://com.mariagracia.clock_it/focus")
    private fun prefs(context: Context) = context.getSharedPreferences(STORE, Context.MODE_PRIVATE)
    private fun manager(context: Context) = context.getSystemService(NotificationManager::class.java)
    private fun alarms(context: Context) = context.getSystemService(AlarmManager::class.java)
    private fun expiry(context: Context) = PendingIntent.getBroadcast(
        context, 0, Intent(context, FocusExpiryReceiver::class.java),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )
    private fun exact(context: Context) = Build.VERSION.SDK_INT < 31 || alarms(context).canScheduleExactAlarms()
    private fun allowed(context: Context) = manager(context).isNotificationPolicyAccessGranted

    fun status(context: Context): Map<String, Boolean> {
        reconcile(context)
        val saved = prefs(context)
        val id = saved.getString("rule", null)
        val active = if (allowed(context) && id != null) {
            runCatching { manager(context).getAutomaticZenRule(id)?.isEnabled == true && wanted(context) }.getOrDefault(false)
        } else false
        return mapOf("supported" to (Build.VERSION.SDK_INT >= 24),
            "enabled" to saved.getBoolean("enabled", false), "granted" to allowed(context),
            "exact" to exact(context), "active" to active)
    }

    fun enable(context: Context, value: Boolean) {
        prefs(context).edit().putBoolean("enabled", value).apply()
        reconcile(context)
    }

    fun sync(context: Context, ends: List<Long>) {
        prefs(context).edit().putLong("until", ends.maxOrNull() ?: 0L).apply()
        reconcile(context)
    }

    fun requestAccess(context: Context) {
        val intent = when {
            !allowed(context) -> Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
            Build.VERSION.SDK_INT >= 31 && !exact(context) -> Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,
                Uri.parse("package:${context.packageName}"))
            else -> return
        }
        context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
    }

    private fun wanted(context: Context) = prefs(context).getBoolean("enabled", false) &&
        prefs(context).getLong("until", 0) > System.currentTimeMillis() && allowed(context) && exact(context)

    fun condition(context: Context) = Condition(conditionId, "Clock it focus",
        if (wanted(context)) Condition.STATE_TRUE else Condition.STATE_FALSE)

    @Suppress("DEPRECATION")
    fun reconcile(context: Context) {
        if (Build.VERSION.SDK_INT < 24) return
        val saved = prefs(context)
        val nm = manager(context)
        var id = saved.getString("rule", null)
        if (!wanted(context)) {
            alarms(context).cancel(expiry(context))
            if (id != null && allowed(context)) {
                runCatching { nm.removeAutomaticZenRule(id) }
                saved.edit().remove("rule").apply()
            }
            return
        }
        try {
            if (id != null && nm.getAutomaticZenRule(id) == null) {
                // Deleting the rule in Settings is an opt-out, not a reason to recreate it.
                saved.edit().putBoolean("enabled", false).remove("rule").apply()
                alarms(context).cancel(expiry(context))
                return
            }
            if (id == null || nm.getAutomaticZenRule(id) == null) {
                val rule = if (Build.VERSION.SDK_INT >= 29) {
                    AutomaticZenRule("Clock it · Focus", null,
                        ComponentName(context, MainActivity::class.java), conditionId, null,
                        NotificationManager.INTERRUPTION_FILTER_PRIORITY, true)
                } else {
                    AutomaticZenRule("Clock it · Focus", ComponentName(context, FocusConditionProvider::class.java),
                        conditionId, NotificationManager.INTERRUPTION_FILTER_PRIORITY, true)
                }
                id = nm.addAutomaticZenRule(rule)
                saved.edit().putString("rule", id).apply()
            }
            // Schedule cleanup before enabling the rule; never leave an unbounded mode.
            alarms(context).setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP,
                saved.getLong("until", 0), expiry(context))
            if (Build.VERSION.SDK_INT >= 29) {
                nm.setAutomaticZenRuleState(id!!, condition(context))
            } else {
                FocusConditionProvider.publish(context)
            }
        } catch (_: RuntimeException) {
            // Permission can be revoked between the checks and the platform calls.
            if (id != null) runCatching { nm.removeAutomaticZenRule(id) }
            saved.edit().remove("rule").apply()
        }
    }
}

class FocusExpiryReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) = FocusMode.reconcile(context)
}

@Suppress("DEPRECATION")
class FocusConditionProvider : ConditionProviderService() {
    override fun onConnected() {
        instance = this
        notifyCondition(FocusMode.condition(this))
    }
    override fun onSubscribe(conditionId: Uri) { notifyCondition(FocusMode.condition(this)) }
    override fun onDestroy() { instance = null; super.onDestroy() }

    companion object {
        private var instance: FocusConditionProvider? = null
        fun publish(context: Context) {
            val provider = instance
            if (provider != null) provider.notifyCondition(FocusMode.condition(context))
            else requestRebind(ComponentName(context, FocusConditionProvider::class.java))
        }
    }
}
