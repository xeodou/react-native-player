/*
* @Author: xeodou
* @Date:   2015
*/

package com.xeodou.audio;


import android.net.Uri;
import android.os.Looper;
import android.support.annotation.Nullable;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.google.android.exoplayer.ExoPlaybackException;
import com.google.android.exoplayer.ExoPlayer;
import com.google.android.exoplayer.MediaCodecAudioTrackRenderer;
import com.google.android.exoplayer.extractor.ExtractorSampleSource;
import com.google.android.exoplayer.upstream.Allocator;
import com.google.android.exoplayer.upstream.DataSource;
import com.google.android.exoplayer.upstream.DefaultAllocator;
import com.google.android.exoplayer.upstream.DefaultUriDataSource;


public class ReactAudio extends ReactContextBaseJavaModule implements ExoPlayer.Listener {

    public static final String REACT_CLASS = "RCTAudio";

    private static final int BUFFER_SEGMENT_SIZE = 64 * 1024;
    private static final int BUFFER_SEGMENT_COUNT = 256;


    private ExoPlayer player = null;
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
    public void prepare(final String url) {
        Looper.prepare();
        if (player == null) {
            player = ExoPlayer.Factory.newInstance(1);
            Uri uri = Uri.parse(url);

            Allocator allocator = new DefaultAllocator(BUFFER_SEGMENT_SIZE);

            DataSource dataSource = new DefaultUriDataSource(context, null);
            ExtractorSampleSource sampleSource = new ExtractorSampleSource(uri, dataSource, allocator,
                    BUFFER_SEGMENT_COUNT * BUFFER_SEGMENT_SIZE);

            MediaCodecAudioTrackRenderer render = new MediaCodecAudioTrackRenderer(sampleSource);
            player.prepare(render);
            player.addListener(this);
            player.setPlayWhenReady(true);
        }

    }

    @Override
    public void onPlayerStateChanged(boolean playWhenReady, int playbackState) {
        if (playbackState == ExoPlayer.STATE_ENDED) {
            player.release();
            player = null;
        }
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
