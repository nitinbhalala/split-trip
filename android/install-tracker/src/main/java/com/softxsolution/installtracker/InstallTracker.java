package com.softxsolution.installtracker;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.provider.Settings;
import android.util.Log;

import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.Charset;
import java.security.MessageDigest;
import java.util.TimeZone;
import java.util.UUID;

/**
 * One-time install tracker. Plain Java, zero dependencies, works in Kotlin and Java apps.
 * Starts automatically via InstallTrackerInitProvider. Config comes from the app's AndroidManifest.xml:
 *   install_tracker.endpoint, install_tracker.api_key (optional), install_tracker.enabled (optional)
 */
public final class InstallTracker {
    private static final String TAG = "InstallTracker";
    private static final String META_ENDPOINT = "install_tracker.endpoint";
    private static final String META_API_KEY = "install_tracker.api_key";
    private static final String META_ENABLED = "install_tracker.enabled";
    private static final String SENT_FILE = "install_tracker.sent";
    private static final String ID_FILE = "install_tracker.id";
    private static final Charset UTF8 = Charset.forName("UTF-8");

    private static volatile boolean running = false;

    private InstallTracker() {}

    /** Reads config from the app manifest and tracks. Called automatically. */
    public static void start(Context context) {
        Context app = appContext(context);
        boolean debug = isDebuggable(app);
        Bundle meta = null;
        try {
            meta = app.getPackageManager()
                    .getApplicationInfo(app.getPackageName(), PackageManager.GET_META_DATA).metaData;
        } catch (Exception ignored) { }

        if ("false".equalsIgnoreCase(metaString(meta, META_ENABLED))) {
            if (debug) Log.i(TAG, "Disabled via manifest.");
            return;
        }
        String endpoint = metaString(meta, META_ENDPOINT);
        if (endpoint == null || endpoint.isEmpty()) {
            if (debug) Log.w(TAG, "No endpoint configured (" + META_ENDPOINT + " missing in AndroidManifest.xml).");
            return;
        }
        String apiKey = metaString(meta, META_API_KEY);
        track(app, endpoint, (apiKey == null || apiKey.isEmpty()) ? null : apiKey);
    }

    /** Manual entry point, if you ever need to bypass auto-start. */
    public static void track(Context context, final String endpoint, final String apiKey) {
        final Context app = appContext(context);
        final boolean debug = isDebuggable(app);
        final File dir = app.getNoBackupFilesDir(); // survives "Clear cache", excluded from Auto Backup
        if (new File(dir, SENT_FILE).exists()) {
            if (debug) Log.d(TAG, "Already tracked for this install.");
            return;
        }
        synchronized (InstallTracker.class) {
            if (running) return;
            running = true;
        }

        new Thread(new Runnable() {
            @Override public void run() {
                HttpURLConnection conn = null;
                try {
                    File idFile = new File(dir, ID_FILE);
                    String installId = idFile.exists() ? readFile(idFile).trim() : "";
                    if (installId.isEmpty()) {
                        installId = UUID.randomUUID().toString();
                        writeFile(idFile, installId);
                    }

                    JSONObject body = new JSONObject();
                    body.put("install_id", installId);
                    body.put("device_key", deviceKey(app, installId));
                    body.put("platform", "android");
                    body.put("app_id", app.getPackageName());
                    body.put("timezone", TimeZone.getDefault().getID());
                    byte[] bytes = body.toString().getBytes(UTF8);

                    conn = (HttpURLConnection) new URL(endpoint).openConnection();
                    conn.setRequestMethod("POST");
                    conn.setConnectTimeout(10000);
                    conn.setReadTimeout(10000);
                    conn.setDoOutput(true);
                    conn.setRequestProperty("Content-Type", "application/json");
                    if (apiKey != null) conn.setRequestProperty("X-Api-Key", apiKey);
                    OutputStream os = conn.getOutputStream();
                    try { os.write(bytes); } finally { os.close(); }

                    int code = conn.getResponseCode();
                    if (code >= 200 && code < 300) {
                        new File(dir, SENT_FILE).createNewFile();
                        if (debug) Log.i(TAG, "Install tracked (HTTP " + code + ").");
                    } else if (debug) {
                        Log.w(TAG, "Server returned HTTP " + code + ". Will retry on next launch.");
                    }
                } catch (Exception e) {
                    if (debug) Log.w(TAG, "Send failed, will retry on next launch: " + e.getMessage());
                } finally {
                    if (conn != null) conn.disconnect();
                    running = false;
                }
            }
        }, "InstallTracker").start();
    }

    private static Context appContext(Context c) {
        Context app = c.getApplicationContext();
        return app != null ? app : c;
    }

    private static boolean isDebuggable(Context app) {
        return (app.getApplicationInfo().flags & ApplicationInfo.FLAG_DEBUGGABLE) != 0;
    }

    private static String metaString(Bundle meta, String key) {
        if (meta == null) return null;
        Object v = meta.get(key); // get() so numeric-looking values aren't lost
        return v == null ? null : v.toString().trim();
    }

    /** SHA-256(ANDROID_ID + package): survives clear data and reinstall; raw ID never leaves the device. */
    @SuppressLint("HardwareIds")
    private static String deviceKey(Context app, String fallback) {
        try {
            String androidId = Settings.Secure.getString(app.getContentResolver(), Settings.Secure.ANDROID_ID);
            if (androidId == null || androidId.isEmpty() || "9774d56d682e549c".equals(androidId)) return fallback;
            byte[] hash = MessageDigest.getInstance("SHA-256")
                    .digest((androidId + ":" + app.getPackageName()).getBytes(UTF8));
            StringBuilder sb = new StringBuilder();
            for (byte b : hash) sb.append(String.format("%02x", b));
            return sb.toString();
        } catch (Exception e) {
            return fallback;
        }
    }

    private static String readFile(File f) throws Exception {
        InputStream in = new FileInputStream(f);
        try {
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            byte[] buf = new byte[256];
            int n;
            while ((n = in.read(buf)) > 0) out.write(buf, 0, n);
            return new String(out.toByteArray(), UTF8);
        } finally { in.close(); }
    }

    private static void writeFile(File f, String s) throws Exception {
        OutputStream out = new FileOutputStream(f);
        try { out.write(s.getBytes(UTF8)); } finally { out.close(); }
    }
}
