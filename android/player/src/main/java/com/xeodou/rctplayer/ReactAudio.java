/*
* @Author: xeodou
* @Date:   2015
*/

package com.xeodou.rctplayer;


import android.net.Uri;
import android.os.Build;
import android.support.annotation.Nullable;

import com.facebook.infer.annotation.Assertions;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.Callback;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.google.android.exoplayer.ExoPlaybackException;
import com.google.android.exoplayer.ExoPlayer;
import com.google.android.exoplayer.MediaCodecAudioTrackRenderer;
import com.google.android.exoplayer.extractor.ExtractorSampleSource;
import com.google.android.exoplayer.upstream.Allocator;
import com.google.android.exoplayer.upstream.DataSource;
import com.google.android.exoplayer.upstream.DefaultAllocator;
import com.google.android.exoplayer.upstream.DefaultUriDataSource;
import com.google.android.exoplayer.util.PlayerControl;
import com.google.android.exoplayer.chunk.Format;


public class ReactAudio extends ReactContextBaseJavaModule implements ExoPlayer.Listener {

    public static final String REACT_CLASS = "ReactAudio";

    private static final int BUFFER_SEGMENT_SIZE = 64 * 1024;
    private static final int BUFFER_SEGMENT_COUNT = 256;


    private ExoPlayer player = null;
    private PlayerControl playerControl = null;
    private ReactApplicationContext context;

    public ReactAudio(ReactApplicationContext reactContext) {
        super(reactContext);
        this.context = reactContext;
    }

    @Override
    public String getName() {
        return REACT_CLASS;
    }

    private void sendEvent(String eventName,
                           @Nullable WritableMap params) {
        this.context
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit(eventName, params);
    }

    @ReactMethod
    public void removeListener() {
        // this could be used on React component unmount
        player.removeListener(this);
    }

    private static String getDefaultUserAgent() {
        StringBuilder result = new StringBuilder(64);
        result.append("Dalvik/");
        result.append(System.getProperty("java.vm.version")); // such as 1.1.0
        result.append(" (Linux; U; Android ");

        String version = Build.VERSION.RELEASE; // "1.0" or "3.4b5"
        result.append(version.length() > 0 ? version : "1.0");

        // add the model for the release build
        if ("REL".equals(Build.VERSION.CODENAME)) {
            String model = Build.MODEL;
            if (model.length() > 0) {
                result.append("; ");
                result.append(model);
            }
        }
        String id = Build.ID; // "MASTER" or "M4-rc20"
        if (id.length() > 0) {
            result.append(" Build/");
            result.append(id);
        }
        result.append(")");
        return result.toString();
    }

    private MediaCodecAudioTrackRenderer buildRender(String url, String agent, boolean auto) {
        Uri uri = Uri.parse(url);

        Allocator allocator = new DefaultAllocator(BUFFER_SEGMENT_SIZE);

        DataSource dataSource = new DefaultUriDataSource(context, agent);
        ExtractorSampleSource sampleSource = new ExtractorSampleSource(uri, dataSource, allocator,
                BUFFER_SEGMENT_COUNT * BUFFER_SEGMENT_SIZE);

        MediaCodecAudioTrackRenderer render = new MediaCodecAudioTrackRenderer(sampleSource);

        return render;
    }

    @ReactMethod
    public void prepare(String url, boolean auto) {
        if (player != null ) {
            player.release();
            player = null;
        }

        player = ExoPlayer.Factory.newInstance(1);
        playerControl = new PlayerControl(player);

        String agent = getDefaultUserAgent();
        MediaCodecAudioTrackRenderer render = this.buildRender(url, agent, auto);
        player.prepare(render);
        player.addListener(this);
        player.setPlayWhenReady(auto);
    }

    @ReactMethod
    public void start() {
        Assertions.assertNotNull(player);
        playerControl.start();
    }

    @ReactMethod
    public void pause() {
        Assertions.assertNotNull(player);
        playerControl.pause();
    }

    @ReactMethod
    public void resume() {
        Assertions.assertNotNull(player);
        playerControl.start();
    }

    @ReactMethod
    public void isPlaying(Callback cb) {
        Assertions.assertNotNull(player);
        cb.invoke(playerControl.isPlaying());
    }

    @ReactMethod
    public void getDuration(Callback cb) {
        Assertions.assertNotNull(player);
        cb.invoke(playerControl.getDuration());
    }

    @ReactMethod
    public void getCurrentPosition(Callback cb) {
        Assertions.assertNotNull(player);
        cb.invoke(playerControl.getCurrentPosition());
    }

    @ReactMethod
    public void getBufferPercentage(Callback cb) {
        Assertions.assertNotNull(player);
        cb.invoke(playerControl.getBufferPercentage());
    }

    @ReactMethod
    public void stop() {
        Assertions.assertNotNull(player);
        player.release();
        player = null;
    }

    @ReactMethod
    public void seekTo(int timeMillis) {
        Assertions.assertNotNull(player);
        playerControl.seekTo(timeMillis);
    }

    @Override
    public void onPlayerStateChanged(boolean playWhenReady, int playbackState) {
        WritableMap params = Arguments.createMap();
        switch (playbackState) {
            // event list from official demo example
            case ExoPlayer.STATE_BUFFERING:
                sendEvent("buffering", params);
                break;
            case ExoPlayer.STATE_ENDED:
                player.release();
                player = null;
                sendEvent("end", params);
                break;
            case ExoPlayer.STATE_IDLE:
                sendEvent("idle", params);
                break;
            case ExoPlayer.STATE_PREPARING:
                sendEvent("preparing", params);
                break;
            case ExoPlayer.STATE_READY:
                sendEvent("ready", params);
                break;
        }
    }

    @ReactMethod
    public void onLoadCompleted(int sourceId, long bytesLoaded, int type, int trigger, Format format,
           long mediaStartTimeMs, long mediaEndTimeMs, long elapsedRealtimeMs, long loadDurationMs) {
        // to make sure media is loaded
        WritableMap params = Arguments.createMap();
        sendEvent("loadCompleted", params);
    }

    @Override
    public void onPlayWhenReadyCommitted() {

    }

    @Override
    public void onPlayerError(ExoPlaybackException error) {
        WritableMap params = Arguments.createMap();
        params.putString("msg", error.getMessage());
        sendEvent("error", params);
    }
}
