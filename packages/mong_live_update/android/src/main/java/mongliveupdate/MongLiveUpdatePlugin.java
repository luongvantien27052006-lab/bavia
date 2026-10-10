// Mọng Fruits — thông báo tiến trình đơn hàng chuẩn Android "Live Update".
//
// Để Android 16 nâng thông báo thành Live Update (chip thanh trạng thái, màn
// khoá, Hyper Island của Xiaomi), thông báo phải: ongoing, có tiêu đề, KHÔNG
// dùng giao diện tự chế (custom view), KHÔNG tô màu nền (colorized), dùng
// ProgressStyle / kiểu chuẩn, và gọi setRequestPromotedOngoing(true).
// Các API của Android 16 được gọi qua reflection để biên dịch với SDK 35.
// Gói Java ngắn (mongliveupdate) để đường dẫn file không quá sâu; tài nguyên R
// vẫn thuộc namespace com.mongfruits.liveupdate (khai báo trong build.gradle).
package mongliveupdate;

import com.mongfruits.liveupdate.R;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.graphics.drawable.Icon;
import android.os.Build;
import android.service.notification.StatusBarNotification;

import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class MongLiveUpdatePlugin implements FlutterPlugin, MethodChannel.MethodCallHandler {
    private static final String CHANNEL_ID = "mong_order_live";
    private static final String TAG = "mong_live";

    private MethodChannel channel;
    private Context context;

    @Override
    public void onAttachedToEngine(FlutterPluginBinding binding) {
        context = binding.getApplicationContext();
        channel = new MethodChannel(binding.getBinaryMessenger(), "mong_live_update");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(FlutterPluginBinding binding) {
        if (channel != null) channel.setMethodCallHandler(null);
        channel = null;
    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        try {
            switch (call.method) {
                case "status":
                    result.success(status());
                    break;
                case "show":
                    show(call);
                    result.success(true);
                    break;
                case "cancel":
                    nm().cancel(TAG, notifId(str(call, "id")));
                    result.success(true);
                    break;
                case "cancelAll":
                    cancelAll();
                    result.success(true);
                    break;
                default:
                    result.notImplemented();
            }
        } catch (Throwable e) {
            result.error("live_update", String.valueOf(e), null);
        }
    }

    // ───────────────────────── trạng thái ─────────────────────────

    private Map<String, Object> status() {
        Map<String, Object> m = new HashMap<>();
        m.put("sdk", Build.VERSION.SDK_INT);
        boolean enabled = Build.VERSION.SDK_INT < 24 || nm().areNotificationsEnabled();
        m.put("notificationsEnabled", enabled);
        m.put("canPromote", canPromote());
        return m;
    }

    private boolean canPromote() {
        if (Build.VERSION.SDK_INT < 36) return false;
        try {
            Method method = NotificationManager.class.getMethod("canPostPromotedNotifications");
            Object r = method.invoke(nm());
            return r instanceof Boolean && (Boolean) r;
        } catch (Throwable e) {
            return false;
        }
    }

    // ───────────────────────── hiện / cập nhật ─────────────────────────

    private void show(MethodCall call) {
        ensureChannel();
        String id = str(call, "id");
        String title = str(call, "title");
        String text = str(call, "text");
        String subText = str(call, "subText");
        String shortText = str(call, "shortText");
        int progress = num(call, "progress", -1);
        boolean ongoing = bool(call, "ongoing", true);
        boolean alert = bool(call, "alert", false);
        Integer color = call.argument("color") instanceof Number
                ? ((Number) call.argument("color")).intValue() : null;
        long timeoutMs = call.argument("timeoutMs") instanceof Number
                ? ((Number) call.argument("timeoutMs")).longValue() : 0L;
        List<Integer> points = new ArrayList<>();
        Object rawPoints = call.argument("points");
        if (rawPoints instanceof List) {
            for (Object p : (List<?>) rawPoints) {
                if (p instanceof Number) points.add(((Number) p).intValue());
            }
        }

        int nid = notifId(id);
        Notification.Builder b = Build.VERSION.SDK_INT >= 26
                ? new Notification.Builder(context, CHANNEL_ID)
                : new Notification.Builder(context);
        b.setSmallIcon(R.drawable.ic_mong_live)
                .setContentTitle(title)
                .setContentText(text)
                .setOngoing(ongoing)
                .setAutoCancel(!ongoing)
                .setOnlyAlertOnce(!alert)
                .setShowWhen(true)
                .setWhen(System.currentTimeMillis())
                .setCategory(ongoing ? Notification.CATEGORY_PROGRESS : Notification.CATEGORY_STATUS)
                .setContentIntent(launchIntent(id, nid));
        if (Build.VERSION.SDK_INT >= 21) b.setVisibility(Notification.VISIBILITY_PUBLIC);
        if (subText != null && !subText.isEmpty()) b.setSubText(subText);
        // Chỉ tô màu icon/thanh tiến trình. KHÔNG setColorized (sẽ mất Live Update).
        if (color != null && Build.VERSION.SDK_INT >= 21) b.setColor(color);
        if (!ongoing && timeoutMs > 0 && Build.VERSION.SDK_INT >= 26) b.setTimeoutAfter(timeoutMs);

        if (progress >= 0) {
            int pct = Math.max(0, Math.min(100, progress));
            if (!(Build.VERSION.SDK_INT >= 36 && applyProgressStyle(b, pct, points, color))) {
                b.setProgress(100, pct, false);
            }
        }

        if (ongoing && Build.VERSION.SDK_INT >= 36) {
            invoke(b, "setRequestPromotedOngoing", boolean.class, true);
            if (shortText != null && !shortText.isEmpty()) {
                invoke(b, "setShortCriticalText", String.class, shortText);
            }
        }

        nm().notify(TAG, nid, b.build());
    }

    /** Android 16: Notification.ProgressStyle (thanh tiến trình có mốc + icon chạy). */
    private boolean applyProgressStyle(Notification.Builder b, int pct, List<Integer> points, Integer color) {
        try {
            Class<?> styleCls = Class.forName("android.app.Notification$ProgressStyle");
            Object style = styleCls.getConstructor().newInstance();

            Class<?> segCls = Class.forName("android.app.Notification$ProgressStyle$Segment");
            Object seg = segCls.getConstructor(int.class).newInstance(100);
            if (color != null) segCls.getMethod("setColor", int.class).invoke(seg, color);
            styleCls.getMethod("setProgressSegments", List.class).invoke(style, Collections.singletonList(seg));

            if (!points.isEmpty()) {
                try {
                    Class<?> ptCls = Class.forName("android.app.Notification$ProgressStyle$Point");
                    List<Object> pts = new ArrayList<>();
                    for (Integer p : points) {
                        Object pt = ptCls.getConstructor(int.class).newInstance(Math.max(1, Math.min(99, p)));
                        if (color != null) ptCls.getMethod("setColor", int.class).invoke(pt, color);
                        pts.add(pt);
                    }
                    styleCls.getMethod("setProgressPoints", List.class).invoke(style, pts);
                } catch (Throwable ignored) {
                    // Không có mốc cũng được.
                }
            }

            try {
                Icon tracker = Icon.createWithResource(context, R.drawable.ic_mong_live);
                styleCls.getMethod("setProgressTrackerIcon", Icon.class).invoke(style, tracker);
            } catch (Throwable ignored) {
                // Không có icon chạy cũng được.
            }

            styleCls.getMethod("setStyledByProgress", boolean.class).invoke(style, true);
            styleCls.getMethod("setProgress", int.class).invoke(style, pct);
            b.setStyle((Notification.Style) style);
            return true;
        } catch (Throwable e) {
            return false;
        }
    }

    private void cancelAll() {
        if (Build.VERSION.SDK_INT >= 23) {
            for (StatusBarNotification s : nm().getActiveNotifications()) {
                if (TAG.equals(s.getTag())) nm().cancel(TAG, s.getId());
            }
        }
    }

    // ───────────────────────── tiện ích ─────────────────────────

    private void ensureChannel() {
        if (Build.VERSION.SDK_INT < 26) return;
        if (nm().getNotificationChannel(CHANNEL_ID) != null) return;
        // Live Update không chấp nhận kênh IMPORTANCE_MIN -> dùng DEFAULT.
        NotificationChannel ch = new NotificationChannel(
                CHANNEL_ID, "Tiến trình đơn hàng", NotificationManager.IMPORTANCE_DEFAULT);
        ch.setDescription("Theo dõi đơn đang pha chế / đang giao");
        ch.setShowBadge(false);
        ch.setLockscreenVisibility(Notification.VISIBILITY_PUBLIC);
        nm().createNotificationChannel(ch);
    }

    private PendingIntent launchIntent(String id, int requestCode) {
        Intent i = context.getPackageManager().getLaunchIntentForPackage(context.getPackageName());
        if (i == null) i = new Intent();
        i.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        i.putExtra("live_order_id", id);
        int flags = PendingIntent.FLAG_UPDATE_CURRENT;
        if (Build.VERSION.SDK_INT >= 23) flags |= PendingIntent.FLAG_IMMUTABLE;
        return PendingIntent.getActivity(context, requestCode, i, flags);
    }

    private static void invoke(Object target, String name, Class<?> type, Object value) {
        try {
            target.getClass().getMethod(name, type).invoke(target, value);
        } catch (Throwable ignored) {
            // Máy không có API này -> bỏ qua.
        }
    }

    private NotificationManager nm() {
        return (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
    }

    private static int notifId(String id) {
        return id == null ? 7301 : (id.hashCode() & 0x7fffffff) % 1000000 + 7301;
    }

    private static String str(MethodCall c, String k) {
        Object v = c.argument(k);
        return v == null ? null : v.toString();
    }

    private static int num(MethodCall c, String k, int def) {
        Object v = c.argument(k);
        return v instanceof Number ? ((Number) v).intValue() : def;
    }

    private static boolean bool(MethodCall c, String k, boolean def) {
        Object v = c.argument(k);
        return v instanceof Boolean ? (Boolean) v : def;
    }
}
