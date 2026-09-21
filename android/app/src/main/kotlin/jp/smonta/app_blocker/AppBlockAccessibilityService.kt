package jp.smonta.app_blocker

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.database.Cursor
import android.database.sqlite.SQLiteDatabase
import android.os.Handler
import android.os.Looper
import android.view.accessibility.AccessibilityEvent
import java.util.Calendar

class AppBlockAccessibilityService : AccessibilityService() {
    private var lastBlockedPackage: String? = null
    private var lastBlockedAt = 0L

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED &&
            event?.eventType != AccessibilityEvent.TYPE_WINDOWS_CHANGED
        ) return
        val foregroundPackage = event.packageName?.toString() ?: return
        if (foregroundPackage == packageName || foregroundPackage == "com.android.systemui") return

        val now = System.currentTimeMillis()
        if (foregroundPackage == lastBlockedPackage && now - lastBlockedAt < 900) return
        val match = findActiveRule(foregroundPackage, now) ?: return
        lastBlockedPackage = foregroundPackage
        lastBlockedAt = now

        performGlobalAction(GLOBAL_ACTION_HOME)
        Handler(Looper.getMainLooper()).postDelayed({
            val intent = Intent(this, BlockedActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                putExtra("rule_name", match.first)
                putExtra("end_at", match.second)
            }
            startActivity(intent)
        }, 120)
    }

    private fun findActiveRule(targetPackage: String, now: Long): Pair<String, Long>? {
        val dbFile = getDatabasePath("app_blocker.db")
        if (!dbFile.exists()) return null
        var db: SQLiteDatabase? = null
        return try {
            db = SQLiteDatabase.openDatabase(dbFile.path, null, SQLiteDatabase.OPEN_READWRITE)
            val cursor = db.rawQuery(
                """
                SELECT r.name, r.mode, r.start_at, r.end_at,
                       r.start_minute, r.end_minute, r.days_mask
                FROM rules r
                INNER JOIN rule_apps a ON a.rule_id = r.id
                WHERE a.package_name = ? AND r.start_at <= ? AND r.end_at > ?
                ORDER BY r.end_at DESC
                """.trimIndent(),
                arrayOf(targetPackage, now.toString(), now.toString()),
            )
            cursor.use {
                while (it.moveToNext()) {
                    val mode = it.getString(1)
                    val endAt = it.getLong(3)
                    if (mode == "one_time") {
                        return Pair(it.getString(0), endAt)
                    }
                    val dailyEnd = dailySessionEnd(it, now)
                    if (dailyEnd != null) {
                        return Pair(it.getString(0), minOf(endAt, dailyEnd))
                    }
                }
            }
            null
        } catch (_: Exception) {
            null
        } finally {
            db?.close()
        }
    }

    private fun dailySessionEnd(cursor: Cursor, now: Long): Long? {
        val calendar = Calendar.getInstance().apply { timeInMillis = now }
        val mondayBasedDay = (calendar.get(Calendar.DAY_OF_WEEK) + 5) % 7
        val mask = cursor.getInt(6)
        if ((mask and (1 shl mondayBasedDay)) == 0) return null
        val minute = calendar.get(Calendar.HOUR_OF_DAY) * 60 + calendar.get(Calendar.MINUTE)
        val startMinute = cursor.getInt(4)
        val endMinute = cursor.getInt(5)
        if (minute < startMinute || minute >= endMinute) return null
        calendar.set(Calendar.HOUR_OF_DAY, endMinute / 60)
        calendar.set(Calendar.MINUTE, endMinute % 60)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        return calendar.timeInMillis
    }

    override fun onInterrupt() = Unit
}
