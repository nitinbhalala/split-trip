package com.softxsolution.installtracker;

import android.content.ContentProvider;
import android.content.ContentValues;
import android.database.Cursor;
import android.net.Uri;

/** Auto-start: Android creates this before Application.onCreate(), so no app code is needed. */
public final class InstallTrackerInitProvider extends ContentProvider {
    @Override public boolean onCreate() {
        if (getContext() != null) InstallTracker.start(getContext());
        return true;
    }
    @Override public Cursor query(Uri u, String[] p, String s, String[] a, String o) { return null; }
    @Override public String getType(Uri u) { return null; }
    @Override public Uri insert(Uri u, ContentValues v) { return null; }
    @Override public int delete(Uri u, String s, String[] a) { return 0; }
    @Override public int update(Uri u, ContentValues v, String s, String[] a) { return 0; }
}
