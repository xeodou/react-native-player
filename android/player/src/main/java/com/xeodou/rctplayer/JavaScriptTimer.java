package com.xeodou.rctplayer;

import android.os.Handler;
import java.util.TimerTask;
import java.util.Timer;

public class JavaScriptTimer {

    // setTimeout, setInterval
    public interface TaskHandle {
        void invalidate();
    }

    public static TaskHandle setTimeout(final Runnable r, long delay) {
        final Handler h = new Handler();
        h.postDelayed(r, delay);
        return new TaskHandle() {
            @Override
            public void invalidate() {
                h.removeCallbacks(r);
            }
        };
    }

    public static TaskHandle setInterval(final Runnable r, long interval) {
        final Timer t = new Timer();
        final Handler h = new Handler();
        t.scheduleAtFixedRate(new TimerTask() {
            @Override
            public void run() {
                h.post(r);
            }
        }, interval, interval);  // Unlike JavaScript, in Java the initial call is immediate, so we put interval instead.
        return new TaskHandle() {
            @Override
            public void invalidate() {
                t.cancel();
                t.purge();
            }
        };
    }
}
