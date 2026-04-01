package com.example.hisn_el_muslim
 
import android.animation.ObjectAnimator
import android.animation.PropertyValuesHolder
import android.animation.ValueAnimator
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Paint
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.view.animation.DecelerateInterpolator
import android.view.animation.LinearInterpolator
import android.view.animation.PathInterpolator
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.RemoteViews
import android.widget.TextView
import androidx.core.app.NotificationCompat
import com.example.hisn_el_muslim.R
import java.util.ArrayList
import java.util.HashSet

class PrayerTimeService : Service() {
    private val CHANNEL_ID = "prayer_notification_channel"
    private val NOTIFICATION_ID = 1001
    private val ALARM_CHANNEL_ID = "fajr_challenge_alarm_channel"
    private val ALARM_NOTIFICATION_ID = 9999
    private var handler: Handler? = null
    private var runnable: Runnable? = null
    private var mediaPlayer: MediaPlayer? = null
    
    // Properties
    private var hijriDate: String = ""
    private var prayerInfoOriginal: String = ""
    private var targetTimestamp: Long = 0
    private var targetPrayerName: String = ""
    private var nextTargetTimestamp: Long = 0
    private var nextTargetPrayerName: String = ""
    private var nextPrayerInfo: String = ""
    private var notificationMode: Int = 0 
    private var challengeTimestamp: Long = 0
    private var challengeTriggered: Boolean = false
    private var prayerTriggered: Boolean = false
    private var serviceStartTime: Long = System.currentTimeMillis()

    // Dhikr properties
    private var dhikrEnabled: Boolean = false
    private var dhikrIntervalMinutes: Int = 15
    private var dhikrList: ArrayList<String> = arrayListOf()
    private var lastDhikrTimestamp: Long = 0

    override fun onCreate() {
        super.onCreate()
        loadData()
    }

    override fun onBind(intent: Intent): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "STOP_SERVICE") {
            stopForeground(true)
            stopSelf()
            return START_NOT_STICKY
        }
        
        if (intent?.action == "TEST_AYAT_OVERLAY") {
            triggerAyatHadithOverlay("Fajr")
            return START_STICKY
        }

        intent?.let { it ->
            hijriDate = it.getStringExtra("hijri_date") ?: hijriDate
            prayerInfoOriginal = it.getStringExtra("prayer_info") ?: prayerInfoOriginal
            val newTargetTimestamp = it.getLongExtra("target_timestamp", 0)
            if (newTargetTimestamp != targetTimestamp) {
                targetTimestamp = newTargetTimestamp
                prayerTriggered = false
            }
            targetPrayerName = it.getStringExtra("next_prayer_name") ?: targetPrayerName
            nextTargetTimestamp = it.getLongExtra("next_target_timestamp", 0)
            nextTargetPrayerName = it.getStringExtra("next_target_prayer_name") ?: nextTargetPrayerName
            nextPrayerInfo = it.getStringExtra("next_prayer_info") ?: nextPrayerInfo
            notificationMode = it.getIntExtra("notification_mode", 0)
        
            val newChallengeTimestamp = it.getLongExtra("challenge_timestamp", 0)
            if (newChallengeTimestamp != challengeTimestamp) {
                challengeTimestamp = newChallengeTimestamp
                challengeTriggered = false
            }

            val wasEnabled = dhikrEnabled
            dhikrEnabled = it.getBooleanExtra("dhikr_enabled", false)
            
            if (dhikrEnabled && (lastDhikrTimestamp == 0L || !wasEnabled)) {
                val now = System.currentTimeMillis()
                lastDhikrTimestamp = now
            }

            if (it.hasExtra("dhikr_interval")) {
                val oldInterval = dhikrIntervalMinutes
                dhikrIntervalMinutes = it.getIntExtra("dhikr_interval", 15)
                if (oldInterval != dhikrIntervalMinutes) {
                    val now = System.currentTimeMillis()
                    lastDhikrTimestamp = now
                }
            }

            val incomingList = it.getStringArrayListExtra("dhikr_list")
            if (incomingList != null) {
                dhikrList = ArrayList(incomingList)
            }
            
            saveData()
        }

        createNotificationChannel()
        createAlarmChannel()
        startUpdatingNotification()

        return START_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(CHANNEL_ID, "Prayer Time Display", NotificationManager.IMPORTANCE_LOW).apply {
                description = "Persistent display of prayer times"
                setSound(null, null)
                enableVibration(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
    }

    private fun createAlarmChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(ALARM_CHANNEL_ID, "Fajr Challenge Alarm", NotificationManager.IMPORTANCE_HIGH).apply {
                description = "Full screen alarm for Fajr Challenge"
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
    }

    private fun startUpdatingNotification() {
        handler?.removeCallbacksAndMessages(null)
        handler = Handler(Looper.getMainLooper())
        runnable = object : Runnable {
            override fun run() {
                updateNotification()
                handler?.postDelayed(this, 1000L)
            }
        }
        handler?.post(runnable!!)
    }

    private fun updateNotification() {
        val now = System.currentTimeMillis()
        var diff = targetTimestamp - now
        
        if (challengeTimestamp > 0 && !challengeTriggered) {
             val challengeDiff = challengeTimestamp - now
             if (challengeDiff <= 0 && challengeDiff > -60000) {
                 challengeTriggered = true
                 triggerAlarm("تحدي الفجر", "حان وقت الاستيقاظ لتحدي الفجر!", "Fajr_Challenge")
             }
        }

        if (targetTimestamp > 0 && !prayerTriggered) {
             val prayerDiff = targetTimestamp - now
              if (prayerDiff <= 0 && prayerDiff > -60000) {
                  prayerTriggered = true
                  // Check user preference from Flutter SharedPreferences
                  val flutterPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                  val isAyatEnabled = flutterPrefs.getBoolean("flutter.ayat_hadith_$targetPrayerName", true)
                  
                  if (isAyatEnabled) {
                      triggerAyatHadithOverlay(targetPrayerName)
                  }
              }
        }

        if (dhikrEnabled && dhikrList.isNotEmpty()) {
            if (lastDhikrTimestamp == 0L) lastDhikrTimestamp = now
            if (now - lastDhikrTimestamp >= (dhikrIntervalMinutes * 60 * 1000)) {
                triggerDhikrOverlay()
                lastDhikrTimestamp = now
                saveData()
            }
        }

        if (diff < -5000 && nextTargetTimestamp > 0 && nextTargetTimestamp > now) {
            targetTimestamp = nextTargetTimestamp
            targetPrayerName = nextTargetPrayerName
            prayerTriggered = false
            prayerInfoOriginal = nextPrayerInfo
            nextTargetTimestamp = 0 
            nextTargetPrayerName = ""
            nextPrayerInfo = ""
            diff = targetTimestamp - now
        }
        
        val remainingTimeText = when {
            diff > 0 -> {
                val hours = diff / 3600000
                val minutes = (diff / 60000) % 60
                val seconds = (diff / 1000) % 60
                String.format("%02d:%02d:%02d", hours, minutes, seconds)
            }
            diff > -60000 -> "الآن"
            else -> ""
        }

        val remainingWithComma = if (remainingTimeText.isNotEmpty()) "  - $remainingTimeText" else ""
        val notification = buildNotification(prayerInfoOriginal, remainingWithComma)
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notification, android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun buildNotification(prayerInfo: String, remainingTime: String): Notification {
        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            action = Intent.ACTION_MAIN
            addCategory(Intent.CATEGORY_LAUNCHER)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            putExtra("screen_to_open", "prayer_times")
        }
        
        val openAppPendingIntent = PendingIntent.getActivity(
            this, 0, openAppIntent, 
            (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0) or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val refreshGpsIntent = Intent(this, RefreshGpsReceiver::class.java).apply {
            action = "com.example.hisn_el_muslim.ACTION_REFRESH_GPS"
        }

        val refreshGpsPendingIntent = PendingIntent.getBroadcast(
            this, 1, refreshGpsIntent, 
            (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0) or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val collapsedView = RemoteViews(packageName, R.layout.notification_prayer_times).apply {
            setTextViewText(R.id.hijri_date, hijriDate)
            setTextViewText(R.id.prayer_info, prayerInfo)
            setTextViewText(R.id.remaining_time, remainingTime)
            setViewVisibility(R.id.button_row, android.view.View.GONE)
        }

        val expandedView = RemoteViews(packageName, R.layout.notification_prayer_times).apply {
            setTextViewText(R.id.hijri_date, hijriDate)
            setTextViewText(R.id.prayer_info, prayerInfo)
            setTextViewText(R.id.remaining_time, remainingTime)
            setViewVisibility(R.id.button_row, android.view.View.VISIBLE)
            setOnClickPendingIntent(R.id.open_app_button, openAppPendingIntent)
            setOnClickPendingIntent(R.id.refresh_gps_button, refreshGpsPendingIntent)
        }

        val uiMode = resources.configuration.uiMode and android.content.res.Configuration.UI_MODE_NIGHT_MASK
        val titleColor = if (uiMode == android.content.res.Configuration.UI_MODE_NIGHT_YES) 0xFFFFFFFF.toInt() else 0xFF1A1A1A.toInt()
        val accentColor = if (uiMode == android.content.res.Configuration.UI_MODE_NIGHT_YES) 0xFFFFD700.toInt() else 0xFF996515.toInt()

        collapsedView.setTextColor(R.id.hijri_date, titleColor)
        collapsedView.setTextColor(R.id.prayer_info, titleColor)
        collapsedView.setTextColor(R.id.remaining_time, accentColor)

        expandedView.setTextColor(R.id.hijri_date, titleColor)
        expandedView.setTextColor(R.id.prayer_info, titleColor)
        expandedView.setTextColor(R.id.remaining_time, accentColor)
        expandedView.setTextColor(R.id.open_app_button, titleColor)
        expandedView.setTextColor(R.id.refresh_gps_button, titleColor)

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setCustomContentView(collapsedView)
            .setCustomBigContentView(expandedView)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setOngoing(true)
            .setShowWhen(false)
            .setWhen(serviceStartTime)
            .setOnlyAlertOnce(true)
            .setContentIntent(openAppPendingIntent)
            .build()
    }

    private fun triggerAlarm(title: String, body: String, prayerName: String?) {
        if (notificationMode == 3) return

        val intent = Intent(this, MainActivity::class.java).apply {
            action = Intent.ACTION_MAIN
            addCategory(Intent.CATEGORY_LAUNCHER)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            if (prayerName != null) putExtra("triggered_prayer", prayerName)
        }
        
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent, 
            (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0) or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val notification = NotificationCompat.Builder(this, ALARM_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setFullScreenIntent(pendingIntent, true)
            .setAutoCancel(true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .build()

        (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).notify(ALARM_NOTIFICATION_ID, notification)
    }

    private fun getArabicPrayerName(englishName: String): String {
        return when(englishName) {
            "Fajr" -> "الفجر"
            "Sunrise" -> "الشروق"
            "Dhuhr" -> "الظهر"
            "Asr" -> "العصر"
            "Maghrib" -> "المغرب"
            "Isha" -> "العشاء"
            else -> englishName
        }
    }

    private fun triggerAyatHadithOverlay(prayerName: String) {
        Handler(Looper.getMainLooper()).post {
            val canDraw = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                Settings.canDrawOverlays(this) else true

            if (!canDraw) {
                Log.w("PrayerTimeService", "No SYSTEM_ALERT_WINDOW permission – falling back to activity for Ayat dialog")
                val fallbackIntent = Intent(this, MainActivity::class.java).apply {
                    action = Intent.ACTION_MAIN
                    addCategory(Intent.CATEGORY_LAUNCHER)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_SINGLE_TOP or
                            Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra("triggered_prayer", prayerName)
                }
                try { startActivity(fallbackIntent) } catch (e: Exception) {
                    Log.e("PrayerTimeService", "Ayat Fallback activity failed: ${e.message}")
                }
                return@post
            }

            // Start Adhan audio
            try {
                mediaPlayer?.release()
                mediaPlayer = MediaPlayer.create(this, R.raw.adan)
                mediaPlayer?.apply {
                    setAudioAttributes(
                        AudioAttributes.Builder()
                            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                            .setUsage(AudioAttributes.USAGE_ALARM)
                            .build()
                    )
                    isLooping = false
                    start()
                }
            } catch (e: Exception) {
                Log.e("PrayerTimeService", "Failed to play Adhan: ${e.message}")
            }

            // Load Custom Fonts
            val amiri = try { Typeface.createFromAsset(assets, "fonts/Amiri-Regular.ttf") } catch (e: Exception) { Typeface.SERIF }
            val amiriQuran = try { Typeface.createFromAsset(assets, "fonts/AmiriQuran-Regular.ttf") } catch (e: Exception) { amiri }

            val wm = getSystemService(Context.WINDOW_SERVICE) as WindowManager
            val dp = resources.displayMetrics.density
            val displayMetrics = resources.displayMetrics
            
            val screenWidth = displayMetrics.widthPixels
            val screenHeight = displayMetrics.heightPixels

            // ═══════════════════════════════════════════════════════════════
            // ROOT: Full-screen backdrop with animated gradient
            // ═══════════════════════════════════════════════════════════════
            val root = FrameLayout(this).apply {
                background = android.graphics.drawable.GradientDrawable().also { gd ->
                    gd.shape = android.graphics.drawable.GradientDrawable.RECTANGLE
                    gd.colors = intArrayOf(
                        0xFF1A0E2E.toInt(), // Solid Deep purple-black
                        0xFF000000.toInt()  // Solid Pure black
                    )
                    gd.gradientType = android.graphics.drawable.GradientDrawable.LINEAR_GRADIENT
                    gd.orientation = android.graphics.drawable.GradientDrawable.Orientation.TOP_BOTTOM
                }
                alpha = 0f
            }

            // ═══════════════════════════════════════════════════════════════
            // ATMOSPHERIC PARTICLES: Floating stars effect
            // ═══════════════════════════════════════════════════════════════
            val particlesContainer = FrameLayout(this)
            for (i in 1..15) {
                val size = ((4 + Math.random() * 8) * dp).toInt()
                val star = View(this).apply {
                    background = android.graphics.drawable.GradientDrawable().also { gd ->
                        gd.shape = android.graphics.drawable.GradientDrawable.OVAL
                        gd.setColor(0x80FFFFFF.toInt())
                    }
                    alpha = 0.3f + (Math.random() * 0.5f).toFloat()
                }
                
                val lp = FrameLayout.LayoutParams(size, size).apply {
                    leftMargin = (Math.random() * screenWidth).toInt()
                    topMargin = (Math.random() * screenHeight).toInt()
                }
                particlesContainer.addView(star, lp)
                
                // Gentle floating animation
                star.animate()
                    .translationY(-30f * dp)
                    .alpha(0.1f)
                    .setDuration((3000 + Math.random() * 2000).toLong())
                    .setStartDelay((Math.random() * 1000).toLong())
                    .withEndAction {
                        star.translationY = 30f * dp
                        star.alpha = 0.8f
                        star.animate()
                            .translationY(0f)
                            .alpha(0.3f)
                            .setDuration((3000 + Math.random() * 2000).toLong())
                            .start()
                    }
                    .start()
            }
            root.addView(particlesContainer, FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            ))

            // ═══════════════════════════════════════════════════════════════
            // SCROLLABLE CONTENT CONTAINER
            // ═══════════════════════════════════════════════════════════════
            val scrollView = android.widget.ScrollView(this).apply {
                isVerticalScrollBarEnabled = false
                isFillViewport = true
            }

            val contentContainer = LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                gravity = Gravity.CENTER
                setPadding((20 * dp).toInt(), (40 * dp).toInt(), (20 * dp).toInt(), (40 * dp).toInt())
            }

            // ═══════════════════════════════════════════════════════════════
            // GLOWING MOSQUE ICON with dynamic pulse
            // ═══════════════════════════════════════════════════════════════
            val iconContainer = FrameLayout(this).apply {
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    setMargins(0, 0, 0, (20 * dp).toInt())
                }
            }

            val iconGlow = View(this).apply {
                val glowSize = (120 * dp).toInt()
                background = android.graphics.drawable.GradientDrawable().also { gd ->
                    gd.shape = android.graphics.drawable.GradientDrawable.OVAL
                    gd.colors = intArrayOf(
                        0x60FFD700.toInt(),
                        0x00FFD700.toInt()
                    )
                    gd.gradientType = android.graphics.drawable.GradientDrawable.RADIAL_GRADIENT
                    gd.gradientRadius = glowSize / 2f
                }
                layoutParams = FrameLayout.LayoutParams(glowSize, glowSize).apply {
                    gravity = Gravity.CENTER
                }
            }

            val iconText = TextView(this).apply {
                text = "🕌"
                textSize = 64f
                gravity = Gravity.CENTER
                elevation = 8 * dp
                layoutParams = FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.WRAP_CONTENT,
                    FrameLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    gravity = Gravity.CENTER
                }
            }

            iconContainer.addView(iconGlow)
            iconContainer.addView(iconText)

            // Smooth pulse animation for both icon and glow
            val pulseAnim = ObjectAnimator.ofPropertyValuesHolder(
                iconText,
                PropertyValuesHolder.ofFloat(View.SCALE_X, 1f, 1.12f, 1f),
                PropertyValuesHolder.ofFloat(View.SCALE_Y, 1f, 1.12f, 1f)
            ).apply {
                duration = 2000
                repeatCount = ValueAnimator.INFINITE
                interpolator = PathInterpolator(0.215f, 0.61f, 0.355f, 1f)
                start()
            }

            val glowPulse = ObjectAnimator.ofPropertyValuesHolder(
                iconGlow,
                PropertyValuesHolder.ofFloat(View.ALPHA, 0.6f, 1f, 0.6f),
                PropertyValuesHolder.ofFloat(View.SCALE_X, 1f, 1.2f, 1f),
                PropertyValuesHolder.ofFloat(View.SCALE_Y, 1f, 1.2f, 1f)
            ).apply {
                duration = 2000
                repeatCount = ValueAnimator.INFINITE
                interpolator = PathInterpolator(0.215f, 0.61f, 0.355f, 1f)
                start()
            }

            // ═══════════════════════════════════════════════════════════════
            // PRAYER TIME ANNOUNCEMENT
            // ═══════════════════════════════════════════════════════════════
            val arabicName = getArabicPrayerName(prayerName)
            
            val timeLabel = TextView(this).apply {
                text = "حان الآن موعد"
                setTextColor(0xCCFFFFFF.toInt())
                textSize = 18f
                gravity = Gravity.CENTER
                typeface = amiri
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    setMargins(0, 0, 0, (8 * dp).toInt())
                }
            }

            val prayerTitle = TextView(this).apply {
                text = "صلاة $arabicName"
                setTextColor(Color.WHITE)
                textSize = 38f
                gravity = Gravity.CENTER
                typeface = amiri
                setShadowLayer(12f, 0f, 4f, 0x80000000.toInt())
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    setMargins(0, 0, 0, (24 * dp).toInt())
                }
            }

            // Decorative divider
            val divider = View(this).apply {
                background = android.graphics.drawable.GradientDrawable().also { gd ->
                    gd.shape = android.graphics.drawable.GradientDrawable.RECTANGLE
                    gd.cornerRadius = 2 * dp
                    gd.colors = intArrayOf(
                        0x00FFD700.toInt(),
                        0xFFFFD700.toInt(),
                        0x00FFD700.toInt()
                    )
                    gd.orientation = android.graphics.drawable.GradientDrawable.Orientation.LEFT_RIGHT
                }
                layoutParams = LinearLayout.LayoutParams(
                    (120 * dp).toInt(),
                    (3 * dp).toInt()
                ).apply {
                    setMargins(0, 0, 0, (32 * dp).toInt())
                }
            }

            // ═══════════════════════════════════════════════════════════════
            // QURAN VERSE CARD - Premium Design
            // ═══════════════════════════════════════════════════════════════

            // 🌟 Card Container
            val verseCard = LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                gravity = Gravity.CENTER
                val cardPadding = (24 * dp).toInt()
                setPadding(cardPadding, cardPadding, cardPadding, cardPadding)

                background = android.graphics.drawable.GradientDrawable().also { gd ->
                    gd.shape = android.graphics.drawable.GradientDrawable.RECTANGLE
                    gd.cornerRadius = 28 * dp

                    // Premium Night Gradient
                    gd.colors = intArrayOf(
                        0xFF2A1B42.toInt(),
                        0xFF1A0F2E.toInt()
                    )
                    gd.orientation = android.graphics.drawable.GradientDrawable.Orientation.TOP_BOTTOM

                    // Rich Gold Border
                    gd.setStroke((2 * dp).toInt(), 0xFFC2A36B.toInt())
                }

                elevation = 6 * dp

                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    setMargins((20 * dp).toInt(), 0, (20 * dp).toInt(), (32 * dp).toInt())
                }
            }

            // 🏷 Header
            val verseHeader = TextView(this).apply {
                text = "قال الله تعالى"
                setTextColor(0xFFD4AF37.toInt()) // Metallic Gold
                textSize = 14f
                gravity = Gravity.CENTER
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    letterSpacing = 0.08f
                }
                typeface = amiri

                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    setMargins(0, 0, 0, (12 * dp).toInt())
                }
            }

            // ✨ Divider
            val cardDivider = View(this).apply {
                background = android.graphics.drawable.GradientDrawable().also { gd ->
                    gd.shape = android.graphics.drawable.GradientDrawable.RECTANGLE
                    gd.cornerRadius = 2 * dp
                    gd.setColor(0x80C2A36B.toInt()) // Brighter gold divider
                }

                layoutParams = LinearLayout.LayoutParams(
                    (60 * dp).toInt(),
                    (2 * dp).toInt()
                ).apply {
                    gravity = Gravity.CENTER
                    setMargins(0, 0, 0, (16 * dp).toInt())
                }
            }

            // 📖 Verse Text
            val verseText = TextView(this).apply {
                text = "إِنَّ الصَّلَاةَ كَانَتْ عَلَى الْمُؤْمِنِينَ\nكِتَابًا مَوْقُوتًا"
                setTextColor(0xFFF5E6BE.toInt()) // Creamy Spiritual White/Gold
                textSize = 26f
                gravity = Gravity.CENTER
                typeface = amiri

                setLineSpacing((10 * dp), 1.1f)
                letterSpacing = 0.02f

                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    setMargins(0, 0, 0, (18 * dp).toInt())
                }
            }

            // 📍 Source
            val verseSource = TextView(this).apply {
                text = "﴿ سورة النساء: ١٠٣ ﴾"
                setTextColor(0xCCB89B5F.toInt()) // Muted Gold source text
                textSize = 15f
                gravity = Gravity.CENTER
                typeface = amiri
            }

            // ✨ Assemble
            verseCard.addView(verseHeader)
            verseCard.addView(cardDivider)
            verseCard.addView(verseText)
            verseCard.addView(verseSource)

            // ═══════════════════════════════════════════════════════════════
            // CLOSE BUTTON - Modern gradient design
            // ═══════════════════════════════════════════════════════════════
            val closeButton = TextView(this).apply {
                text = "إغلاق"
                setTextColor(Color.WHITE)
                textSize = 20f
                gravity = Gravity.CENTER
                typeface = amiriQuran
                val btnPadding = (18 * dp).toInt()
                setPadding(btnPadding, btnPadding, btnPadding, btnPadding)
                background = android.graphics.drawable.GradientDrawable().also { gd ->
                    gd.shape = android.graphics.drawable.GradientDrawable.RECTANGLE
                    gd.cornerRadius = 28 * dp
                    gd.colors = intArrayOf(
                        0xFFD64463.toInt(),
                        0xFFB73856.toInt()
                    )
                    gd.orientation = android.graphics.drawable.GradientDrawable.Orientation.LEFT_RIGHT
                }
                elevation = 8 * dp
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    setMargins((16 * dp).toInt(), 0, (16 * dp).toInt(), 0)
                }
            }

            // Assemble content
            contentContainer.addView(iconContainer)
            contentContainer.addView(timeLabel)
            contentContainer.addView(prayerTitle)
            contentContainer.addView(divider)
            contentContainer.addView(verseCard)
            contentContainer.addView(closeButton)

            scrollView.addView(contentContainer)
            root.addView(scrollView, FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            ))

            // ═══════════════════════════════════════════════════════════════
            // WINDOW PARAMETERS
            // ═══════════════════════════════════════════════════════════════
            val overlayType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE

            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                overlayType,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                        WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                        WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                        WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                        WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
                PixelFormat.TRANSLUCENT
            )

            try {
                wm.addView(root, params)
                
                // Entrance animation
                root.animate()
                    .alpha(1f)
                    .setDuration(700)
                    .setInterpolator(PathInterpolator(0.215f, 0.61f, 0.355f, 1f))
                    .start()

                contentContainer.alpha = 0f
                contentContainer.translationY = 60f * dp
                contentContainer.animate()
                    .alpha(1f)
                    .translationY(0f)
                    .setDuration(800)
                    .setStartDelay(200)
                    .setInterpolator(PathInterpolator(0.215f, 0.61f, 0.355f, 1f))
                    .start()

            } catch (e: Exception) {
                Log.e("PrayerTimeService", "Overlay failed: ${e.message}")
                return@post
            }

            // ═══════════════════════════════════════════════════════════════
            // DISMISS HANDLER
            // ═══════════════════════════════════════════════════════════════
            val dismissOverlay = {
                pulseAnim.cancel()
                glowPulse.cancel()
                
                try {
                    mediaPlayer?.stop()
                    mediaPlayer?.release()
                    mediaPlayer = null
                } catch (e: Exception) {}

                root.animate()
                    .alpha(0f)
                    .setDuration(400)
                    .withEndAction {
                        try { wm.removeView(root) } catch (e: Exception) {}
                    }
                    .start()

                val stopIntent = Intent(this@PrayerTimeService, StopAdhanReceiver::class.java)
                sendBroadcast(stopIntent)
            }

            closeButton.setOnClickListener { dismissOverlay() }
            root.setOnClickListener { dismissOverlay() }
            contentContainer.setOnClickListener { /* Prevent backdrop dismiss */ }
        }
    }

    private fun triggerDhikrOverlay() {
        Handler(Looper.getMainLooper()).post {
            val dhikr = if (dhikrList.isNotEmpty())
                dhikrList[(dhikrList.indices).random()] else "سبحان الله"

            val canDraw = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                Settings.canDrawOverlays(this) else true

            if (!canDraw) {
                Log.w("PrayerTimeService", "No SYSTEM_ALERT_WINDOW permission – falling back to activity")
                val intent = Intent(this, MainActivity::class.java).apply {
                    action = Intent.ACTION_MAIN
                    addCategory(Intent.CATEGORY_LAUNCHER)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_SINGLE_TOP or
                            Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra("triggered_dhikr", true)
                }
                try { startActivity(intent) } catch (e: Exception) {
                    Log.e("PrayerTimeService", "Fallback activity failed: ${e.message}")
                }
                return@post
            }

            val wm = getSystemService(Context.WINDOW_SERVICE) as WindowManager
            val displayMetrics = resources.displayMetrics
            val dp = displayMetrics.density

            // Load Custom Font
            val amiri = try { Typeface.createFromAsset(assets, "fonts/Amiri-Regular.ttf") } catch (e: Exception) { Typeface.SERIF }

            // ═══════════════════════════════════════════════════════════════
            // MODERN CARD WITH SHIMMER EFFECT
            // ═══════════════════════════════════════════════════════════════
            // val cardWidth = (280 * dp).toInt()
            val cardWidth = (280f * dp)
            
            val root = FrameLayout(this).apply {
                background = GradientDrawable().also { gd ->
                    gd.shape = GradientDrawable.RECTANGLE
                    gd.cornerRadius = 20 * dp
                    gd.colors = intArrayOf(0xFFD64463.toInt(), 0xFFFFD700.toInt())
                    gd.gradientType = GradientDrawable.LINEAR_GRADIENT
                    gd.orientation = GradientDrawable.Orientation.TL_BR
                }
                setLayerType(View.LAYER_TYPE_SOFTWARE, null)
                val shadowPaint = Paint().apply {
                    setShadowLayer(24 * dp, 0f, 10 * dp, 0x59000000.toInt())
                }
                background = background
                alpha = 0f
                scaleX = 0.8f
                scaleY = 0.6f
            }

            val innerCard = LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                gravity = Gravity.CENTER
                val vPadding = (4 * dp).toInt()
                val hPadding = (20 * dp).toInt()
                setPadding(hPadding, vPadding, hPadding, vPadding)
                background = android.graphics.drawable.GradientDrawable().also { gd ->
                    gd.shape = android.graphics.drawable.GradientDrawable.RECTANGLE
                    // gd.cornerRadius = 18.5f * dp
                    gd.cornerRadius = 18.5f * dp + 0.5f
                    gd.colors = intArrayOf(
                        0xD91A1A24.toInt(),
                        0xD9000000.toInt()
                    )
                    gd.orientation = android.graphics.drawable.GradientDrawable.Orientation.TOP_BOTTOM
                }
            }


            // Dhikr text
            val dhikrText = TextView(this).apply {
                text = dhikr
                setTextColor(Color.WHITE)
                textSize = 18f
                gravity = Gravity.CENTER
                typeface = amiri
                layoutDirection = View.LAYOUT_DIRECTION_RTL
                maxLines = 3
                // setLineSpacing((6 * dp), 1f)
                setLineSpacing(0f, 1.4f)
                paint.isSubpixelText = true
                paint.isAntiAlias = true
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    setMargins(0, 0, 0, (12 * dp).toInt())
                }
            }

            // Progress bar container
            val progressContainer = FrameLayout(this).apply {
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    (3 * dp).toInt()
                )
            }

            val progressTrack = View(this).apply {
                background = android.graphics.drawable.GradientDrawable().also { gd ->
                    gd.shape = android.graphics.drawable.GradientDrawable.RECTANGLE
                    gd.cornerRadius = 2 * dp
                    gd.setColor(0x30FFFFFF.toInt())
                }
                layoutParams = FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT
                )
            }

            val progressFill = View(this).apply {
                background = android.graphics.drawable.GradientDrawable().also { gd ->
                    gd.shape = android.graphics.drawable.GradientDrawable.RECTANGLE
                    gd.cornerRadius = 2 * dp
                    gd.colors = intArrayOf(0xFFD64463.toInt(), 0xFFFFD700.toInt())
                    gd.orientation = android.graphics.drawable.GradientDrawable.Orientation.LEFT_RIGHT
                }
                layoutParams = FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT
                )
            }

            progressContainer.addView(progressTrack)
            progressContainer.addView(progressFill)

            innerCard.addView(dhikrText)
            innerCard.addView(progressContainer)

            val margin = (2 * dp).toInt()
            root.addView(innerCard, FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            ).apply { setMargins(margin, margin, margin, margin) })

            // Window parameters
            val overlayType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE

            val params = WindowManager.LayoutParams(
                cardWidth.toInt(),
                WindowManager.LayoutParams.WRAP_CONTENT,
                overlayType,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                        WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.CENTER
            }

            // ═══════════════════════════════════════════════════════════════
            // ANIMATION & AUTO-DISMISS (MATCH FLUTTER)
            // ═══════════════════════════════════════════════════════════════
            val totalMs = 5000L
            
            val exitAnimation = Runnable {
                root.animate()
                    .alpha(0f)
                    .scaleX(0.9f)
                    .scaleY(0.9f)
                    .setDuration(300)
                    .setInterpolator(PathInterpolator(0.215f, 0.61f, 0.355f, 1f))
                    .withEndAction {
                        try { wm.removeView(root) } catch (e: Exception) {}
                    }
                    .start()
            }

            val progressAnimator = ValueAnimator.ofFloat(1f, 0f).apply {
                duration = totalMs
                interpolator = LinearInterpolator()
                addUpdateListener { animator ->
                    val fraction = animator.animatedValue as Float
                    val lp = progressFill.layoutParams as FrameLayout.LayoutParams
                    lp.width = (cardWidth.toInt() * fraction).toInt()
                    progressFill.layoutParams = lp
                }
                addListener(object : AnimatorListenerAdapter() {
                    override fun onAnimationEnd(animation: Animator) {
                        exitAnimation.run()
                    }
                })
            }

            try {
                wm.addView(root, params)
                
                // Entrance
                root.animate()
                    .alpha(1f)
                    .scaleX(1f)
                    .scaleY(1f)
                    .setDuration(500)
                    .setInterpolator(PathInterpolator(0.215f, 0.61f, 0.355f, 1f))
                    .withEndAction {
                        progressAnimator.start()
                    }
                    .start()

            } catch (e: Exception) {
                Log.e("PrayerTimeService", "Failed to add overlay view: ${e.message}")
                return@post
            }

            root.setOnClickListener {
                progressAnimator.cancel()
                exitAnimation.run()
            }
        }
    }

    private fun saveData() {
        val prefs = getSharedPreferences("prayer_service_prefs", Context.MODE_PRIVATE)
        prefs.edit().apply {
            putString("hijri_date", hijriDate)
            putString("prayer_info", prayerInfoOriginal)
            putLong("target_timestamp", targetTimestamp)
            putString("next_prayer_name", targetPrayerName)
            putLong("next_target_timestamp", nextTargetTimestamp)
            putString("next_target_prayer_name", nextTargetPrayerName)
            putString("next_prayer_info", nextPrayerInfo)
            putLong("challenge_timestamp", challengeTimestamp)
            putBoolean("challenge_triggered", challengeTriggered)
            putBoolean("prayer_triggered", prayerTriggered)
            putBoolean("dhikr_enabled", dhikrEnabled)
            putInt("dhikr_interval", dhikrIntervalMinutes)
            putLong("last_dhikr_timestamp", lastDhikrTimestamp)
            putStringSet("dhikr_list", dhikrList.toSet())
            apply()
        }
    }

    private fun loadData() {
        val prefs = getSharedPreferences("prayer_service_prefs", Context.MODE_PRIVATE)
        hijriDate = prefs.getString("hijri_date", "") ?: ""
        prayerInfoOriginal = prefs.getString("prayer_info", "") ?: ""
        targetTimestamp = prefs.getLong("target_timestamp", 0)
        targetPrayerName = prefs.getString("next_prayer_name", "") ?: ""
        nextTargetTimestamp = prefs.getLong("next_target_timestamp", 0)
        nextTargetPrayerName = prefs.getString("next_target_prayer_name", "") ?: ""
        nextPrayerInfo = prefs.getString("next_prayer_info", "") ?: ""
        challengeTimestamp = prefs.getLong("challenge_timestamp", 0)
        challengeTriggered = prefs.getBoolean("challenge_triggered", false)
        prayerTriggered = prefs.getBoolean("prayer_triggered", false)
        dhikrEnabled = prefs.getBoolean("dhikr_enabled", false)
        dhikrIntervalMinutes = prefs.getInt("dhikr_interval", 15)
        lastDhikrTimestamp = prefs.getLong("last_dhikr_timestamp", 0)
        val savedList: Set<String>? = prefs.getStringSet("dhikr_list", null)
        if (savedList != null) dhikrList = ArrayList(savedList.toList())
    }
    
    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
    }
    
    override fun onDestroy() {
        handler?.removeCallbacksAndMessages(null)
        super.onDestroy()
    }
}