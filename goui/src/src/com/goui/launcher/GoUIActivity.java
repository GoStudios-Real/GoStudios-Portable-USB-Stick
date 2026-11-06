package com.goui.launcher;

import android.app.Activity;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.net.Uri;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.LinearGradient;
import android.graphics.Paint;
import android.graphics.Shader;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.GradientDrawable;
import android.graphics.drawable.Drawable;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.text.InputType;
import android.view.Gravity;
import android.view.View;
import android.view.Window;
import android.widget.FrameLayout;
import android.widget.GridLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.EditText;

import java.io.InputStream;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

/**
 * GoUI 4.9 - GoStudios portable Android shell.
 * Boot splash -> GoStudios Account gate -> shell with tabs:
 * Home (3 app Spots), GoStudios Gaming Hub, Play Store, Account.
 */
public class GoUIActivity extends Activity {

    private static final long SPLASH_MS = 2600;
    private static final int PER_SPOT = 12;
    private static final String TAG_GAMING[] = {
        "com.godevice.app", "com.playtree.app",
        "com.microsoft.xboxcloudgaming", "com.microsoft.xboxapp",
        "com.google.android.play.games", "com.mojang.minecraftpe",
        "com.epicgames.fortnite", "com.activision.callofduty.shooter",
        "com.rockstargames.gtasa", "com.dts.freefiremax",
        "com.mobile.legends", "com.tencent.ig",
    };
    private static final String PLAYSTORE = "com.android.vending";

    private final Handler handler = new Handler(Looper.getMainLooper());
    private FrameLayout root;
    private LinearLayout body;
    private PackageManager pm;
    private SharedPreferences prefs;
    private TextView spotLabel, accountChip, tabTitle;
    private final List<AppEntry> allApps = new ArrayList<>();
    private int spotIndex = 0;
    private String currentTab = "home";
    private boolean splashDone = false;
    private View homeTabBtn, gamesTabBtn, playTabBtn, acctTabBtn, settingsTabBtn, aboutTabBtn;

    static class AppEntry {
        final String label; final String pkg; final Drawable icon;
        AppEntry(String l, String p, Drawable i) { label = l; pkg = p; icon = i; }
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        pm = getPackageManager();
        prefs = getSharedPreferences("gostudios", MODE_PRIVATE);

        root = new FrameLayout(this);
        root.setBackground(new BitmapDrawable(getResources(), gradientWallpaper()));
        setContentView(root);

        if (prefs.getString("user", null) == null) {
            showAccountGate();
        } else {
            showBootSplash();
        }
    }

    /* ---------------- GoStudios Account system ---------------- */

    private void showAccountGate() {
        LinearLayout page = centered();

        TextView brand = txt("GoStudios", 40f, Color.WHITE);
        page.addView(brand);
        page.addView(txt("GoStudios Account", 16f, Color.parseColor("#80CBC4")));
        page.addView(spacer(64));

        final EditText user = field("Username");
        final EditText pass = field("Password");
        pass.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_PASSWORD);
        page.addView(user);
        page.addView(spacer(16));
        page.addView(pass);
        page.addView(spacer(24));

        TextView msg = txt("", 13f, Color.parseColor("#EF9A9A"));
        page.addView(msg);

        TextView signIn = btn("Sign In");
        signIn.setOnClickListener(v -> {
            String u = user.getText().toString().trim();
            String p = pass.getText().toString();
            if (u.isEmpty() || p.isEmpty()) { msg.setText("Enter username and password."); return; }
            String saved = prefs.getString("pass", null);
            if (saved != null && !saved.equals(p)) { msg.setText("Wrong password for " + u + "."); return; }
            prefs.edit().putString("user", u).putString("pass", p).apply();
            showBootSplash();
        });
        page.addView(signIn);
        page.addView(spacer(12));

        TextView create = btn("Create GoStudios Account");
        create.setOnClickListener(v -> {
            String u = user.getText().toString().trim();
            String p = pass.getText().toString();
            if (u.isEmpty() || p.isEmpty()) { msg.setText("Choose a username and password."); return; }
            if (prefs.contains("user") && !prefs.getString("user", "").equals(u)) {
                msg.setText("Account exists: " + prefs.getString("user", "") + ". Sign in instead.");
                return;
            }
            prefs.edit().putString("user", u).putString("pass", p).apply();
            showBootSplash();
        });
        page.addView(create);

        setView(padFull(page));
    }

    /* ---------------- Boot screen ---------------- */

    private void showBootSplash() {
        LinearLayout splash = centered();
        splash.setBackgroundColor(Color.parseColor("#080C28"));

        ImageView logo = new ImageView(this);
        try { logo.setImageDrawable(pm.getApplicationIcon(getPackageName())); }
        catch (Exception e) { logo.setImageDrawable(getDrawable(R.drawable.icon)); }
        logo.setPadding(0, 0, 0, 48);
        splash.addView(logo);

        splash.addView(txt("GoStudios", 42f, Color.WHITE));
        splash.addView(txt("GoStudios Portable USB Stick", 16f, Color.parseColor("#80CBC4")));
        TextView ver = txt("GoUI 4.9  •  Android 16", 14f, Color.parseColor("#7E57C2"));
        ver.setPadding(0, 64, 0, 0);
        splash.addView(ver);

        setView(splash);
        handler.postDelayed(() -> {
            if (!isFinishing()) { splashDone = true; showShell(); }
        }, SPLASH_MS);
    }

    /* ---------------- Shell: header + tabs + body ---------------- */

    private void showShell() {
        LinearLayout page = new LinearLayout(this);
        page.setOrientation(LinearLayout.VERTICAL);
        page.setPadding(36, 48, 36, 0);

        // Header
        LinearLayout header = new LinearLayout(this);
        header.setOrientation(LinearLayout.HORIZONTAL);
        header.setGravity(Gravity.CENTER_VERTICAL);
        TextView title = txt("GoUI 4.9", 26f, Color.WHITE);
        header.addView(title);
        TextView spacer = txt("   ", 12f, Color.WHITE);
        header.addView(spacer);
        accountChip = txt("👤 " + prefs.getString("user", ""), 13f, Color.parseColor("#80CBC4"));
        accountChip.setGravity(Gravity.END);
        LinearLayout.LayoutParams chipLp = new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f);
        accountChip.setLayoutParams(chipLp);
        header.addView(accountChip);
        page.addView(header);

        // Tabs
        LinearLayout tabs = new LinearLayout(this);
        tabs.setOrientation(LinearLayout.HORIZONTAL);
        tabs.setPadding(0, 20, 0, 8);
        homeTabBtn = tabButton("Home");
        gamesTabBtn = tabButton("Gaming Hub");
        playTabBtn = tabButton("Play Store");
        acctTabBtn = tabButton("Account");
        settingsTabBtn = tabButton("Settings");
        aboutTabBtn = tabButton("About");
        tabs.addView(homeTabBtn); tabs.addView(gamesTabBtn);
        tabs.addView(playTabBtn); tabs.addView(acctTabBtn);
        tabs.addView(settingsTabBtn); tabs.addView(aboutTabBtn);
        page.addView(tabs);

        tabTitle = txt("", 15f, Color.parseColor("#B2EBF2"));
        tabTitle.setPadding(0, 12, 0, 4);
        page.addView(tabTitle);

        body = new LinearLayout(this);
        body.setOrientation(LinearLayout.VERTICAL);
        body.setPadding(0, 8, 0, 0);
        LinearLayout bodyWrap = new LinearLayout(this);
        bodyWrap.setOrientation(LinearLayout.VERTICAL);
        bodyWrap.addView(body);
        page.addView(bodyWrap);

        setView(padFull(page));
        loadApps();
        showTab("home");
    }

    private View tabButton(final String name) {
        TextView b = txt(name, 13f, Color.parseColor("#9E9E9E"));
        b.setPadding(18, 12, 18, 12);
        GradientDrawable gd = new GradientDrawable();
        gd.setColor(Color.TRANSPARENT);
        gd.setCornerRadius(24f);
        b.setBackground(gd);
        b.setOnClickListener(v -> showTab(
            name.equals("Home") ? "home" :
            name.equals("Gaming Hub") ? "games" :
            name.equals("Play Store") ? "play" :
            name.equals("Account") ? "acct" :
            name.equals("Settings") ? "settings" : "about"));
        return b;
    }

    private void markTab(View active) {
        View[] all = { homeTabBtn, gamesTabBtn, playTabBtn, acctTabBtn, settingsTabBtn, aboutTabBtn };
        for (View v : all) {
            TextView tv = (TextView) v;
            boolean on = (v == active);
            tv.setTextColor(on ? Color.WHITE : Color.parseColor("#9E9E9E"));
            tv.setBackgroundColor(on ? Color.parseColor("#263238") : Color.TRANSPARENT);
        }
    }

    private void showTab(String tab) {
        currentTab = tab;
        body.removeAllViews();
        if (tab.equals("home")) { markTab(homeTabBtn); showHome(); }
        else if (tab.equals("games")) { markTab(gamesTabBtn); showGamingHub(); }
        else if (tab.equals("play")) { markTab(playTabBtn); showPlayStore(); }
        else if (tab.equals("acct")) { markTab(acctTabBtn); showAccount(); }
        else { markTab(aboutTabBtn); showAbout(); }
    }

    /* ---------------- Home: multiple Spots ---------------- */

    private void showHome() {
        tabTitle.setText("Home • swipe your apps across Spots");
        spotLabel = txt(spotName(), 13f, Color.parseColor("#80CBC4"));
        body.addView(spotLabel);

        final LinearLayout gridWrap = new LinearLayout(this);
        gridWrap.setOrientation(LinearLayout.VERTICAL);
        body.addView(gridWrap);

        int pages = Math.max(1, (allApps.size() + PER_SPOT - 1) / PER_SPOT);
        if (spotIndex >= pages) spotIndex = 0;

        GridLayout grid = new GridLayout(this);
        grid.setColumnCount(4);
        int from = spotIndex * PER_SPOT;
        int to = Math.min(allApps.size(), from + PER_SPOT);
        for (int i = from; i < to; i++) grid.addView(tile(allApps.get(i)));
        gridWrap.addView(grid);

        if (allApps.isEmpty()) gridWrap.addView(txt("No apps found on this spot.", 14f, Color.WHITE));

        // Spot navigation
        LinearLayout nav = new LinearLayout(this);
        nav.setOrientation(LinearLayout.HORIZONTAL);
        nav.setGravity(Gravity.CENTER);
        nav.setPadding(0, 28, 0, 0);
        TextView prev = btn("◀ Spot");
        TextView next = btn("Spot ▶");
        final int total = pages;
        prev.setOnClickListener(v -> { spotIndex = (spotIndex - 1 + total) % total; showTab("home"); });
        next.setOnClickListener(v -> { spotIndex = (spotIndex + 1) % total; showTab("home"); });
        nav.addView(prev); nav.addView(spacer(20)); nav.addView(next);
        body.addView(nav);
    }

    private String spotName() {
        return "Spot " + (spotIndex + 1) + " of " +
            Math.max(1, (allApps.size() + PER_SPOT - 1) / PER_SPOT);
    }

    /* ---------------- GoStudios Gaming Hub ---------------- */

    private void showGamingHub() {
        tabTitle.setText("GoStudios Gaming Hub");

        TextView hero = txt("🎮  GoStudios Gaming Hub", 24f, Color.WHITE);
        hero.setPadding(0, 8, 0, 4);
        body.addView(hero);
        body.addView(txt("Your preinstalled games and services", 13f, Color.parseColor("#80CBC4")));
        body.addView(spacer(16));

        // GoStudios picks (preinstalled gaming apps)
        body.addView(section("GoStudios Picks"));
        GridLayout picks = new GridLayout(this);
        picks.setColumnCount(4);
        int shown = 0;
        for (String p : TAG_GAMING) {
            AppEntry e = findByPackage(p);
            if (e != null) { picks.addView(tile(e)); shown++; }
        }
        if (shown == 0) picks.addView(txt("Launch a game via Home spots — they appear here automatically.", 13f, Color.WHITE));
        body.addView(picks);
        body.addView(spacer(24));

        // Web apps (cloud services)
        body.addView(section("Web Apps"));
        GridLayout web = new GridLayout(this);
        web.setColumnCount(4);
        web.addView(webTile("Xbox Cloud Gaming", "https://play.xbox.com/", "#107C10"));
        web.addView(webTile("PlayTree", "https://playtree-play.base44.app/", "#7E57C2"));
        web.addView(webTile("GeForce NOW", "https://play.geforcenow.com/", "#76B900"));
        web.addView(webTile("Steam Link", "https://store.steampowered.com/remoteplay", "#1B2838"));
        web.addView(webTile("YouTube", "https://www.youtube.com/", "#FF0000"));
        web.addView(webTile("Discord", "https://discord.com/app", "#5865F2"));
        body.addView(web);
        body.addView(spacer(24));

        // All launchable apps (so every installed game is reachable)
        body.addView(section("All Apps"));
        GridLayout all = new GridLayout(this);
        all.setColumnCount(4);
        for (AppEntry e : allApps) all.addView(tile(e));
        body.addView(all);
    }

    private TextView section(String s) {
        TextView t = txt(s, 14f, Color.parseColor("#7E57C2"));
        t.setPadding(0, 4, 0, 10);
        return t;
    }

    /* ---------------- Play Store ---------------- */

    private void showPlayStore() {
        tabTitle.setText("Google Play Store");
        LinearLayout page = new LinearLayout(this);
        page.setOrientation(LinearLayout.VERTICAL);
        page.setGravity(Gravity.CENTER_HORIZONTAL);
        page.setPadding(0, 48, 0, 0);

        ImageView icon = new ImageView(this);
        try { icon.setImageDrawable(pm.getApplicationIcon(PLAYSTORE)); }
        catch (Exception e) { icon.setImageDrawable(getDrawable(R.drawable.icon)); }
        icon.setLayoutParams(new LinearLayout.LayoutParams(220, 220));
        page.addView(icon);

        page.addView(spacer(24));
        page.addView(txt("Google Play Store", 26f, Color.WHITE));
        page.addView(txt("Apps, games & GoStudios content", 13f, Color.parseColor("#80CBC4")));
        page.addView(spacer(32));

        TextView open = btn("Open Play Store");
        open.setOnClickListener(v -> {
            Intent i = pm.getLaunchIntentForPackage(PLAYSTORE);
            if (i != null) startActivity(i);
        });
        page.addView(open);

        boolean has = pm.getLaunchIntentForPackage(PLAYSTORE) != null;
        TextView state = txt(has
            ? "Play Store is installed on this system image."
            : "Play Store not found on this image — use the Google Play image variant.",
            12f, has ? Color.parseColor("#A5D6A7") : Color.parseColor("#EF9A9A"));
        state.setGravity(Gravity.CENTER);
        state.setPadding(0, 24, 0, 0);
        page.addView(state);

        body.addView(page);
    }

    /* ---------------- Account tab ---------------- */

    private void showAccount() {
        tabTitle.setText("GoStudios Account");
        body.addView(txt("👤  " + prefs.getString("user", ""), 26f, Color.WHITE));
        body.addView(spacer(8));
        body.addView(txt("GoStudios Account • signed in on this device", 13f, Color.parseColor("#80CBC4")));
        body.addView(spacer(24));

        body.addView(kv("OS", "Android " + Build.VERSION.RELEASE + " (API " + Build.VERSION.SDK_INT + ")"));
        body.addView(kv("Shell", "GoUI 4.9"));
        body.addView(kv("Device", Build.MANUFACTURER + " " + Build.MODEL));
        body.addView(kv("Account", prefs.getString("user", "")));
        body.addView(kv("USB", "GoStudios Portable USB Stick"));
        body.addView(spacer(32));

        TextView replay = btn("Replay boot screen");
        replay.setOnClickListener(v -> showBootSplash());
        body.addView(replay);
        body.addView(spacer(12));

        TextView out = btn("Sign out");
        out.setOnClickListener(v -> {
            prefs.edit().remove("user").remove("pass").apply();
            splashDone = false;
            showAccountGate();
        });
        body.addView(out);
    }

    private void showAbout() {
        tabTitle.setText("About");
        body.addView(txt("GoStudios Portable USB Stick", 24f, Color.WHITE));
        body.addView(txt("GoUI 4.9  \u2022  Android 16", 14f, Color.parseColor("#80CBC4")));
        body.addView(spacer(16));
        body.addView(kv("Tagline", "Your Android. Your USB. Any PC."));
        body.addView(kv("Version", "GoUI 4.9"));
        body.addView(kv("OS", "Android " + Build.VERSION.RELEASE));
        body.addView(kv("Trademark", "GoStudios, GoUI, GoDevice, PlayTree"));
        body.addView(kv("Copyright", "\u00a9 2026 GoStudios"));
        body.addView(spacer(24));
        TextView gh = btn("Open GitHub");
        gh.setOnClickListener(v -> {
            try { startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse("https://github.com/GoStudios-Real/GoStudios-Portable-USB-Stick"))); } catch (Exception ignored) { }
        });
        body.addView(gh);
    }

    private void showSettings() {
        tabTitle.setText("Settings");
        body.addView(txt("\u2699\ufe0f  GoUI Settings", 24f, Color.WHITE));
        body.addView(spacer(16));
        body.addView(kv("Shell", "GoUI 4.9"));
        body.addView(kv("Theme", "Dark (GoStudios)"));
        body.addView(kv("Spots per page", "12 apps"));
        body.addView(kv("Fullscreen", "On"));
        body.addView(kv("On-screen keyboard", "System IME"));
        body.addView(spacer(24));
        TextView replay = btn("Replay boot screen");
        replay.setOnClickListener(v -> showBootSplash());
        body.addView(replay);
        body.addView(spacer(12));
        TextView home = btn("Set GoUI as Home");
        home.setOnClickListener(v -> {
            try { Runtime.getRuntime().exec("cmd package set-home-activity com.goui.launcher/.GoUIActivity"); } catch (Exception ignored) { }
        });
        body.addView(home);
    }

    private View kv(String k, String v) {
        LinearLayout outer = new LinearLayout(this);
        outer.setOrientation(LinearLayout.VERTICAL);
        LinearLayout row = new LinearLayout(this);
        TextView a = txt(k, 13f, Color.parseColor("#9E9E9E"));
        a.setLayoutParams(new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f));
        TextView b = txt(v, 13f, Color.WHITE);
        b.setLayoutParams(new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 2f));
        row.addView(a); row.addView(b);
        outer.addView(row);
        outer.addView(divider());
        return outer;
    }

    private View divider() { View v = new View(this); v.setLayoutParams(new LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, 1)); v.setBackgroundColor(Color.parseColor("#33FFFFFF")); return v; }

    /* ---------------- App loading + tiles ---------------- */

    private void loadApps() {
        allApps.clear();
        Intent main = new Intent(Intent.ACTION_MAIN);
        main.addCategory(Intent.CATEGORY_LAUNCHER);
        List<ResolveInfo> ris = pm.queryIntentActivities(main, 0);
        for (ResolveInfo ri : ris) {
            String pkg = ri.activityInfo.packageName;
            if (pkg.equals(getPackageName())) continue;
            Drawable ic;
            try { ic = pm.getApplicationIcon(pkg); } catch (Exception e) { ic = getDrawable(R.drawable.icon); }
            allApps.add(new AppEntry(String.valueOf(ri.loadLabel(pm)), pkg, ic));
        }
        Collections.sort(allApps, new Comparator<AppEntry>() {
            public int compare(AppEntry a, AppEntry b) { return a.label.compareToIgnoreCase(b.label); }
        });
    }

    private AppEntry findByPackage(String pkg) {
        for (AppEntry e : allApps) if (e.pkg.equals(pkg)) return e;
        return null;
    }

    private View tile(AppEntry e) {
        LinearLayout t = new LinearLayout(this);
        t.setOrientation(LinearLayout.VERTICAL);
        t.setGravity(Gravity.CENTER);
        t.setPadding(24, 24, 24, 24);
        GradientDrawable tileBg = new GradientDrawable();
        tileBg.setColor(Color.parseColor("#1C2331"));
        tileBg.setCornerRadius(32f);
        t.setBackground(tileBg);
        ImageView ic = new ImageView(this);
        ic.setImageDrawable(e.icon);
        ic.setLayoutParams(new LinearLayout.LayoutParams(128, 128));
        t.addView(ic);
        TextView n = txt(e.label, 12f, Color.WHITE);
        n.setGravity(Gravity.CENTER);
        n.setMaxLines(2);
        n.setPadding(0, 12, 0, 0);
        t.addView(n);
        t.setOnClickListener(v -> {
            Intent i = pm.getLaunchIntentForPackage(e.pkg);
            if (i != null) startActivity(i);
        });
        GridLayout.LayoutParams lp = new GridLayout.LayoutParams();
        lp.width = 0;
        lp.columnSpec = GridLayout.spec(GridLayout.UNDEFINED, 1f);
        lp.setMargins(8, 8, 8, 8);
        t.setLayoutParams(lp);
        return t;
    }

    private View webTile(String label, final String url, String color) {
        LinearLayout t = new LinearLayout(this);
        t.setOrientation(LinearLayout.VERTICAL);
        t.setGravity(Gravity.CENTER);
        t.setPadding(24, 24, 24, 24);
        TextView ic = txt("🌐", 40f, Color.parseColor(color));
        ic.setGravity(Gravity.CENTER);
        t.addView(ic);
        TextView n = txt(label, 12f, Color.WHITE);
        n.setGravity(Gravity.CENTER);
        n.setMaxLines(2);
        n.setPadding(0, 12, 0, 0);
        t.addView(n);
        t.setOnClickListener(v -> {
            try { startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(url))); }
            catch (Exception ignored) { }
        });
        GridLayout.LayoutParams lp = new GridLayout.LayoutParams();
        lp.width = 0;
        lp.columnSpec = GridLayout.spec(GridLayout.UNDEFINED, 1f);
        lp.setMargins(8, 8, 8, 8);
        t.setLayoutParams(lp);
        return t;
    }

    private LinearLayout centered() {
        LinearLayout l = new LinearLayout(this);
        l.setOrientation(LinearLayout.VERTICAL);
        l.setGravity(Gravity.CENTER);
        return l;
    }

    private void setView(View v) {
        root.removeAllViews();
        root.addView(v, new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT));
    }

    private ScrollView padFull(View v) {
        ScrollView sv = new ScrollView(this);
        sv.setFillViewport(true);
        sv.addView(v);
        FrameLayout.LayoutParams lp = new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT);
        lp.setMargins(48, 48, 48, 64);
        sv.setLayoutParams(lp);
        return sv;
    }

    private TextView txt(String s, float size, int color) {
        TextView t = new TextView(this);
        t.setText(s); t.setTextSize(size); t.setTextColor(color);
        return t;
    }

    private TextView btn(String s) {
        TextView t = txt(s, 15f, Color.WHITE);
        t.setGravity(Gravity.CENTER);
        t.setPadding(40, 22, 40, 22);
        GradientDrawable gd = new GradientDrawable();
        gd.setColor(Color.parseColor("#00897B"));
        gd.setCornerRadius(48f);
        t.setBackground(gd);
        return t;
    }

    private EditText field(String hint) {
        EditText e = new EditText(this);
        e.setHint(hint);
        e.setSingleLine(true);
        e.setTextColor(Color.WHITE);
        e.setHintTextColor(Color.parseColor("#78909C"));
        e.setBackgroundColor(Color.parseColor("#1C2331"));
        e.setPadding(24, 18, 24, 18);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        lp.width = 700;
        e.setLayoutParams(lp);
        return e;
    }

    private View spacer(int h) {
        View v = new View(this);
        v.setLayoutParams(new LinearLayout.LayoutParams(1, h));
        return v;
    }

    private Bitmap gradientWallpaper() {
        try {
            InputStream in = getResources().openRawResource(R.raw.wallpaper);
            Bitmap bmp = BitmapFactory.decodeStream(in);
            if (bmp != null) return bmp;
        } catch (Exception ignored) { }
        Bitmap fallback = Bitmap.createBitmap(8, 16, Bitmap.Config.ARGB_8888);
        Canvas c = new Canvas(fallback);
        Paint p = new Paint();
        p.setShader(new LinearGradient(0, 0, 0, 16,
                Color.parseColor("#080C28"), Color.parseColor("#3C145A"),
                Shader.TileMode.CLAMP));
        c.drawRect(0, 0, 8, 16, p);
        return fallback;
    }

    @Override
    public void onBackPressed() {
        if (!splashDone) return;
        if (body != null && !currentTab.equals("home")) { showTab("home"); return; }
        if (body != null) { showTab("home"); }
    }
}
