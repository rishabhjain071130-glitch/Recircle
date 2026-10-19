package com.payrolldesk.app;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.print.PrintAttributes;
import android.print.PrintManager;
import android.webkit.JavascriptInterface;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Toast;
import java.io.OutputStream;
import android.util.Base64;

public class MainActivity extends Activity {
    private static final int PICK_FILE = 41;
    private static final int SAVE_FILE = 42;
    private WebView web;
    private ValueCallback<Uri[]> uploadCallback;
    private byte[] pendingDownload;

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        web = new WebView(this);
        setContentView(web);
        web.getSettings().setJavaScriptEnabled(true);
        web.getSettings().setDomStorageEnabled(true);
        web.getSettings().setAllowFileAccess(true);
        web.getSettings().setAllowContentAccess(true);
        web.getSettings().setAllowFileAccessFromFileURLs(false);
        web.getSettings().setAllowUniversalAccessFromFileURLs(false);
        web.addJavascriptInterface(new AppBridge(), "PayrollDeskAndroid");
        web.setWebViewClient(new WebViewClient() {
            @Override public void onPageFinished(WebView view, String url) {
                view.evaluateJavascript("window.print=function(){window.PayrollDeskAndroid.printPage()}", null);
            }
        });
        web.setWebChromeClient(new WebChromeClient() {
            @Override public boolean onShowFileChooser(WebView view, ValueCallback<Uri[]> callback, FileChooserParams params) {
                if (uploadCallback != null) uploadCallback.onReceiveValue(null);
                uploadCallback = callback;
                Intent intent = params.createIntent();
                try { startActivityForResult(intent, PICK_FILE); return true; }
                catch (Exception e) { uploadCallback = null; return false; }
            }
        });
        web.loadUrl("file:///android_asset/index.html");
        web.setFocusableInTouchMode(true);
    }

    private final class AppBridge {
        @JavascriptInterface public void saveFile(String name, String encoded) {
            try {
                pendingDownload = Base64.decode(encoded, Base64.DEFAULT);
                runOnUiThread(() -> {
                    Intent i = new Intent(Intent.ACTION_CREATE_DOCUMENT);
                    i.addCategory(Intent.CATEGORY_OPENABLE);
                    i.setType(mimeFor(name));
                    i.putExtra(Intent.EXTRA_TITLE, name);
                    startActivityForResult(i, SAVE_FILE);
                });
            } catch (Exception e) { runOnUiThread(() -> Toast.makeText(MainActivity.this, "File taiyaar nahi ho saki", Toast.LENGTH_SHORT).show()); }
        }
        @JavascriptInterface public void printPage() { runOnUiThread(() -> {
            PrintManager manager = (PrintManager) getSystemService(PRINT_SERVICE);
            manager.print("Payroll Desk", web.createPrintDocumentAdapter("Payroll Desk"), new PrintAttributes.Builder().build());
        }); }
    }

    private String mimeFor(String name) {
        String n = name.toLowerCase();
        if (n.endsWith(".pdf")) return "application/pdf";
        if (n.endsWith(".xlsx")) return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
        if (n.endsWith(".zip")) return "application/zip";
        if (n.endsWith(".png")) return "image/png";
        if (n.endsWith(".json")) return "application/json";
        return "application/octet-stream";
    }

    @Override protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == PICK_FILE && uploadCallback != null) {
            Uri[] result = resultCode == RESULT_OK && data != null && data.getData() != null ? new Uri[]{data.getData()} : null;
            uploadCallback.onReceiveValue(result); uploadCallback = null;
        } else if (requestCode == SAVE_FILE && resultCode == RESULT_OK && data != null && data.getData() != null && pendingDownload != null) {
            try (OutputStream out = getContentResolver().openOutputStream(data.getData())) { out.write(pendingDownload); Toast.makeText(this, "File save ho gayi", Toast.LENGTH_SHORT).show(); }
            catch (Exception e) { Toast.makeText(this, "File save nahi ho saki", Toast.LENGTH_SHORT).show(); }
            pendingDownload = null;
        } else if (requestCode == SAVE_FILE) pendingDownload = null;
    }

    @Override public void onBackPressed() { if (web != null && web.canGoBack()) web.goBack(); else super.onBackPressed(); }
    @Override protected void onDestroy() { if (web != null) { web.removeJavascriptInterface("PayrollDeskAndroid"); web.destroy(); } super.onDestroy(); }
}
