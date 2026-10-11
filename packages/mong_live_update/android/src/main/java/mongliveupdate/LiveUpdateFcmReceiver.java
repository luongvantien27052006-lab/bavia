// Nhận tin FCM data {type: live_activity, orderId, status} và vẽ lại thông báo
// tiến trình đơn ngay lập tức (native), kể cả khi app ở nền hoặc đã thoát.
package mongliveupdate;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;

public class LiveUpdateFcmReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        try {
            Bundle ex = intent.getExtras();
            if (ex == null) return;
            if (!"live_activity".equals(ex.getString("type"))) return;
            String orderId = ex.getString("orderId");
            String status = ex.getString("status");
            if (orderId == null || status == null) return;
            MongLiveUpdatePlugin.postOrderStatus(context.getApplicationContext(), orderId, status, true);
        } catch (Throwable ignored) {
            // Không bao giờ làm crash app vì thông báo.
        }
    }
}
