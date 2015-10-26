/*
* @Author: xeodou
* @Date:   2015
*/

package com.xeodou.audio;


import android.media.AudioManager;
import android.media.MediaPlayer;
import android.net.Uri;
import android.support.annotation.Nullable;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import java.io.IOException;


public class ReactAudio extends ReactContextBaseJavaModule implements MediaPlayer.OnPreparedListener{

    public static final String REACT_CLASS = "RCTAudio";

    private MediaPlayer mediaPlayer = null;
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
        try {
            if(mediaPlayer == null) {
                mediaPlayer = new MediaPlayer();
                mediaPlayer.setAudioStreamType(AudioManager.STREAM_MUSIC);
            }
            mediaPlayer.setDataSource(this.context, Uri.parse(url));
            mediaPlayer.prepareAsync();
        } catch (IOException e) {
            e.printStackTrace();
            WritableMap params = Arguments.createMap();
            params.putString("msg", e.getMessage());
            sendEvent("error", params);
            return;
        }
    }

    @ReactMethod
    public void stop() {
        if (mediaPlayer != null && mediaPlayer.isPlaying()) {
            mediaPlayer.stop();
        }
    }

    @ReactMethod
    public void start() {
        if (!mediaPlayer.isPlaying()) {
            mediaPlayer.start();
        }
    }

    @ReactMethod
    public void pause() {
        if (mediaPlayer.isPlaying()) {
            mediaPlayer.pause();
        }
    }

    @Override
    public void onPrepared(MediaPlayer mediaPlayer) {
        mediaPlayer.start();
        WritableMap params = Arguments.createMap();
        sendEvent("prepare", params);
    }
}
