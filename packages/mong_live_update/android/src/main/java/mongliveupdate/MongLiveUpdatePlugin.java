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
        post(context, str(call, "id"), str(call, "title"), str(call, "text"),
                str(call, "subText"), str(call, "shortText"), num(call, "progress", -1),
                points, bool(call, "ongoing", true), bool(call, "alert", false), color, timeoutMs);
    }

    // ───────────────────────── trạng thái đơn (dùng cho receiver FCM) ─────────────────────────

    private static final int BRAND = 0xFFD9653B;
    private static final int OK = 0xFF2E9E5B;
    private static final int BAD = 0xFFD64545;
    private static final List<Integer> STEP_POINTS = java.util.Arrays.asList(20, 45, 70, 88);

    /** Khớp bảng _steps trong lib/services/order_live_activity.dart. */
    static void postOrderStatus(Context ctx, String orderId, String status, boolean alert) {
        if ("REFUNDED".equals(status)) status = "CANCELLED";
        String label, sub, shortText;
        int progress;
        switch (status) {
            case "PENDING": label = "Chờ quán xác nhận"; shortText = "Chờ quán"; sub = "Quán sẽ xác nhận đơn trong giây lát"; progress = 8; break;
            case "CONFIRMED": label = "Đã xác nhận"; shortText = "Đã nhận"; sub = "Quán đã nhận đơn của bạn"; progress = 20; break;
            case "IN_PROGRESS": label = "Đang pha chế"; shortText = "Đang pha"; sub = "Đồ uống của bạn đang được chuẩn bị"; progress = 45; break;
            case "READY": label = "Đã sẵn sàng"; shortText = "Sẵn sàng"; sub = "Đơn đã pha xong"; progress = 70; break;
            case "DELIVERING": label = "Đang giao"; shortText = "Đang giao"; sub = "Shipper đang trên đường tới bạn"; progress = 88; break;
            case "DELIVERED": label = "Hoàn thành"; shortText = "Xong"; sub = "Cảm ơn bạn đã chọn Mọng Fruits!"; progress = 100; break;
            case "CANCELLED": label = "Đơn đã huỷ"; shortText = "Đã huỷ"; sub = "Liên hệ quán nếu cần hỗ trợ"; progress = -1; break;
            default: return;
        }
        String hex = orderId.replace("-", "");
        String code = hex.substring(0, Math.min(8, hex.length())).toUpperCase();
        String id = "order-" + orderId;
        boolean terminal = "DELIVERED".equals(status) || "CANCELLED".equals(status);
        if (terminal) {
            post(ctx, id, label, sub, "Mọng Fruits · Đơn #" + code, null, progress,
                    new ArrayList<Integer>(), false, alert,
                    "DELIVERED".equals(status) ? OK : BAD, 30L * 60L * 1000L);
        } else {
            post(ctx, id, label, sub, "Mọng Fruits · Đơn #" + code, shortText, progress,
                    STEP_POINTS, true, alert, BRAND, 0L);
        }
    }

    // ───────────────────────── vẽ thông báo ─────────────────────────

    static void post(Context ctx, String id, String title, String text, String subText,
                     String shortText, int progress, List<Integer> points, boolean ongoing,
                     boolean alert, Integer color, long timeoutMs) {
        NotificationManager nm = nm(ctx);
        if (Build.VERSION.SDK_INT >= 24 && !nm.areNotificationsEnabled()) return;
        ensureChannel(ctx);

        int nid = notifId(id);
        Notification.Builder b = Build.VERSION.SDK_INT >= 26
                ? new Notification.Builder(ctx, CHANNEL_ID)
                : new Notification.Builder(ctx);
        b.setSmallIcon(R.drawable.ic_mong_live)
                .setContentTitle(title)
                .setContentText(text)
                .setOngoing(ongoing)
                .setAutoCancel(!ongoing)
                .setOnlyAlertOnce(!alert)
                .setShowWhen(true)
                .setWhen(System.currentTimeMillis())
                .setCategory(ongoing ? Notification.CATEGORY_PROGRESS : Notification.CATEGORY_STATUS)
                .setContentIntent(launchIntent(ctx, id, nid));
        if (Build.VERSION.SDK_INT >= 21) b.setVisibility(Notification.VISIBILITY_PUBLIC);
        if (subText != null && !subText.isEmpty()) b.setSubText(subText);
        // Chỉ tô màu icon/thanh tiến trình. KHÔNG setColorized (sẽ mất Live Update).
        if (color != null && Build.VERSION.SDK_INT >= 21) b.setColor(color);
        if (!ongoing && timeoutMs > 0 && Build.VERSION.SDK_INT >= 26) b.setTimeoutAfter(timeoutMs);

        if (progress >= 0) {
            int pct = Math.max(0, Math.min(100, progress));
            if (!(Build.VERSION.SDK_INT >= 36 && applyProgressStyle(ctx, b, pct, points, color))) {
                b.setProgress(100, pct, false);
            }
        }

        if (ongoing && Build.VERSION.SDK_INT >= 36) {
            invoke(b, "setRequestPromotedOngoing", boolean.class, true);
            if (shortText != null && !shortText.isEmpty()) {
                invoke(b, "setShortCriticalText", String.class, shortText);
            }
        }

        nm.notify(TAG, nid, b.build());
    }

    /** Android 16: Notification.ProgressStyle (thanh tiến trình có mốc + icon chạy). */
    private static boolean applyProgressStyle(Context ctx, Notification.Builder b, int pct, List<Integer> points, Integer color) {
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
                Icon tracker = Icon.createWithResource(ctx, R.drawable.ic_mong_live);
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

    private static void ensureChannel(Context ctx) {
        if (Build.VERSION.SDK_INT < 26) return;
        NotificationManager nm = nm(ctx);
        if (nm.getNotificationChannel(CHANNEL_ID) != null) return;
        // Live Update không chấp nhận kênh IMPORTANCE_MIN -> dùng DEFAULT.
        NotificationChannel ch = new NotificationChannel(
                CHANNEL_ID, "Tiến trình đơn hàng", NotificationManager.IMPORTANCE_DEFAULT);
        ch.setDescription("Theo dõi đơn đang pha chế / đang giao");
        ch.setShowBadge(false);
        ch.setLockscreenVisibility(Notification.VISIBILITY_PUBLIC);
        nm.createNotificationChannel(ch);
    }

    private static PendingIntent launchIntent(Context ctx, String id, int requestCode) {
        Intent i = ctx.getPackageManager().getLaunchIntentForPackage(ctx.getPackageName());
        if (i == null) i = new Intent();
        i.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        i.putExtra("live_order_id", id);
        int flags = PendingIntent.FLAG_UPDATE_CURRENT;
        if (Build.VERSION.SDK_INT >= 23) flags |= PendingIntent.FLAG_IMMUTABLE;
        return PendingIntent.getActivity(ctx, requestCode, i, flags);
    }

    private static void invoke(Object target, String name, Class<?> type, Object value) {
        try {
            target.getClass().getMethod(name, type).invoke(target, value);
        } catch (Throwable ignored) {
            // Máy không có API này -> bỏ qua.
        }
    }

    private NotificationManager nm() {
        return nm(context);
    }

    private static NotificationManager nm(Context ctx) {
        return (NotificationManager) ctx.getSystemService(Context.NOTIFICATION_SERVICE);
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
