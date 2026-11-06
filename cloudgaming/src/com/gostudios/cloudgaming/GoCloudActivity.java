package com.gostudios.cloudgaming;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.net.Uri;
import android.os.Bundle;
import android.view.Gravity;
import android.view.Window;
import android.widget.GridLayout;
import android.widget.LinearLayout;
import android.widget.TextView;

public class GoCloudActivity extends Activity {
    static class Service { final String name; final String url; final String color;
        Service(String n, String u, String c){ name=n; url=u; color=c; } }

    private static final Service[] SERVICES = {
        new Service("Xbox Cloud Gaming", "https://play.xbox.com/", "#107C10"),
        new Service("GeForce NOW", "https://play.geforcenow.com/", "#76B900"),
        new Service("Steam Link", "https://store.steampowered.com/remoteplay", "#1B2838"),
        new Service("Amazon Luna", "https://luna.amazon.com/", "#00A8E1"),
        new Service("Boosteroid", "https://boosteroid.com/", "#FF6B00"),
        new Service("PlayTree", "https://playtree-play.base44.app/", "#7E57C2"),
        new Service("YouTube Gaming", "https://www.youtube.com/gaming", "#FF0000"),
        new Service("Discord", "https://discord.com/app", "#5865F2"),
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(32, 48, 32, 32);
        root.setBackgroundColor(Color.parseColor("#080C28"));

        TextView title = new TextView(this);
        title.setText("\u2601  GoCloud Gaming");
        title.setTextSize(28f);
        title.setTextColor(Color.WHITE);
        title.setGravity(Gravity.CENTER);
        root.addView(title);

        TextView sub = new TextView(this);
        sub.setText("Cloud gaming services - tap to play");
        sub.setTextSize(13f);
        sub.setTextColor(Color.parseColor("#80CBC4"));
        sub.setGravity(Gravity.CENTER);
        sub.setPadding(0, 8, 0, 24);
        root.addView(sub);

        GridLayout grid = new GridLayout(this);
        grid.setColumnCount(2);
        for (Service s : SERVICES) {
            LinearLayout tile = new LinearLayout(this);
            tile.setOrientation(LinearLayout.VERTICAL);
            tile.setGravity(Gravity.CENTER);
            tile.setPadding(20, 24, 20, 24);
            GradientDrawable bg = new GradientDrawable();
            bg.setColor(Color.parseColor(s.color));
            bg.setCornerRadius(24f);
            tile.setBackground(bg);
            TextView ic = new TextView(this);
            ic.setText("\u2601");
            ic.setTextSize(32f);
            ic.setTextColor(Color.WHITE);
            ic.setGravity(Gravity.CENTER);
            tile.addView(ic);
            TextView nm = new TextView(this);
            nm.setText(s.name);
            nm.setTextSize(13f);
            nm.setTextColor(Color.WHITE);
            nm.setGravity(Gravity.CENTER);
            nm.setPadding(0, 8, 0, 0);
            tile.addView(nm);
            tile.setOnClickListener(v -> {
                try { startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(s.url))); } catch (Exception ignored) { }
            });
            GridLayout.LayoutParams lp = new GridLayout.LayoutParams();
            lp.width = 0;
            lp.columnSpec = GridLayout.spec(GridLayout.UNDEFINED, 1f);
            lp.setMargins(8, 8, 8, 8);
            tile.setLayoutParams(lp);
            grid.addView(tile);
        }
        root.addView(grid);

        TextView footer = new TextView(this);
        footer.setText("GoStudios Cloud Gaming \u00a9 2026");
        footer.setTextSize(11f);
        footer.setTextColor(Color.parseColor("#78909C"));
        footer.setGravity(Gravity.CENTER);
        footer.setPadding(0, 24, 0, 0);
        root.addView(footer);

        setContentView(root);
    }
}