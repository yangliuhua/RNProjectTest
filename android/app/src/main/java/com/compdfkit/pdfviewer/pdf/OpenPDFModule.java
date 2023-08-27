package com.compdfkit.pdfviewer.pdf;

import android.content.Intent;

import androidx.annotation.NonNull;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

public class OpenPDFModule extends ReactContextBaseJavaModule {

    private ReactContext mReactContext;

    public OpenPDFModule(ReactApplicationContext context) {
        super(context);
        this.mReactContext = context;
    }


    @NonNull
    @Override
    public String getName() {
        return "OpenPDFModule";
    }

    @ReactMethod
    public void openPDF() {
        Intent intent = new Intent(mReactContext, PDFActivity.class);
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        mReactContext.startActivity(intent);
    }

    @ReactMethod
    public void openPDFByPath(String filePath) {
        Intent intent = new Intent(mReactContext, PDFActivity.class);
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        intent.putExtra(PDFActivity.EXTRA_FILE_PATH, filePath);
        mReactContext.startActivity(intent);
    }
}
