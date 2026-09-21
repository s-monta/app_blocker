package jp.smonta.app_blocker

import android.app.Activity
import android.graphics.Color
import android.os.Bundle
import android.view.Gravity
import android.view.ViewGroup
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class BlockedActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.statusBarColor = Color.rgb(246, 243, 234)
        window.navigationBarColor = Color.rgb(246, 243, 234)
        val ruleName = intent.getStringExtra("rule_name") ?: "集中タイム"
        val endAt = intent.getLongExtra("end_at", 0L)
        val endText = if (endAt > 0) {
            SimpleDateFormat("M月d日 HH:mm", Locale.JAPAN).format(Date(endAt))
        } else {
            "設定した時刻"
        }
        val density = resources.displayMetrics.density
        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding((32 * density).toInt(), 0, (32 * density).toInt(), 0)
            setBackgroundColor(Color.rgb(246, 243, 234))
        }
        content.addView(TextView(this).apply {
            text = "◷"
            textSize = 56f
            gravity = Gravity.CENTER
            setTextColor(Color.rgb(63, 107, 79))
        })
        content.addView(TextView(this).apply {
            text = "いまは、ひと休み。"
            textSize = 28f
            gravity = Gravity.CENTER
            setTextColor(Color.rgb(23, 33, 27))
            setPadding(0, (18 * density).toInt(), 0, 0)
        })
        content.addView(TextView(this).apply {
            text = "「$ruleName」が有効です。\n$endText までこのアプリは開けません。"
            textSize = 16f
            gravity = Gravity.CENTER
            setLineSpacing(0f, 1.45f)
            setTextColor(Color.rgb(82, 96, 88))
            setPadding(0, (20 * density).toInt(), 0, (30 * density).toInt())
        })
        content.addView(Button(this).apply {
            text = "ホームに戻る"
            textSize = 15f
            isAllCaps = false
            setOnClickListener { finish() }
        }, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, (54 * density).toInt()))
        setContentView(content)
    }
}
