/**
 * Copyright © 2014-2023 PDF Technologies, Inc. All Rights Reserved.
 * <p>
 * THIS SOURCE CODE AND ANY ACCOMPANYING DOCUMENTATION ARE PROTECTED BY INTERNATIONAL COPYRIGHT LAW
 * AND MAY NOT BE RESOLD OR REDISTRIBUTED. USAGE IS BOUND TO THE ComPDFKit LICENSE AGREEMENT.
 * UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS SUBJECT TO CIVIL AND CRIMINAL PENALTIES.
 * This notice may not be removed from this file.
 */
package com.compdfkit.pdfviewer.pdf;

import static com.compdfkit.tools.contenteditor.CEditToolbar.SELECT_AREA_IMAGE;
import static com.compdfkit.tools.contenteditor.CEditToolbar.SELECT_AREA_TEXT;
import static com.compdfkit.ui.contextmenu.CPDFContextMenuShowHelper.AddEditImageArea;
import static com.compdfkit.ui.contextmenu.CPDFContextMenuShowHelper.ReplaceEditImageArea;

import android.Manifest;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.provider.Settings;
import android.view.View;
import android.widget.Toast;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.compdfkit.core.annotation.CPDFAnnotation;
import com.compdfkit.core.annotation.form.CPDFWidget;
import com.compdfkit.core.edit.CPDFEditManager;
import com.compdfkit.pdfviewer.R;
import com.compdfkit.pdfviewer.databinding.PdfSampleActivityBinding;
import com.compdfkit.tools.common.activity.CBasicActivity;
import com.compdfkit.tools.common.contextmenu.CPDFContextMenuHelper;
import com.compdfkit.tools.common.utils.CFileUtils;
import com.compdfkit.tools.common.utils.CUriUtil;
import com.compdfkit.tools.common.utils.annotation.CPDFAnnotationManager;
import com.compdfkit.tools.common.utils.dialog.CAlertDialog;
import com.compdfkit.tools.common.utils.task.CExtractAssetFileTask;
import com.compdfkit.tools.common.utils.window.CPopupMenuWindow;
import com.compdfkit.tools.common.views.pdfbota.CPDFBOTA;
import com.compdfkit.tools.common.views.pdfbota.CPDFBotaDialogFragment;
import com.compdfkit.tools.common.views.pdfbota.CPDFBotaFragmentTabs;
import com.compdfkit.tools.common.views.pdfproperties.CAnnotationType;
import com.compdfkit.tools.common.views.pdfproperties.pdfstyle.CAnnotStyle;
import com.compdfkit.tools.common.views.pdfproperties.pdfstyle.CStyleDialogFragment;
import com.compdfkit.tools.common.views.pdfproperties.pdfstyle.CStyleType;
import com.compdfkit.tools.common.views.pdfproperties.pdfstyle.manager.CStyleManager;
import com.compdfkit.tools.common.views.pdfview.CPreviewMode;
import com.compdfkit.tools.contenteditor.CPDFEditType;
import com.compdfkit.tools.viewer.pdfsearch.CSearchResultDialogFragment;
import com.compdfkit.ui.contextmenu.IContextMenuShowListener;
import com.compdfkit.ui.proxy.form.CPDFComboboxWidgetImpl;
import com.compdfkit.ui.proxy.form.CPDFListboxWidgetImpl;
import com.compdfkit.ui.proxy.form.CPDFPushbuttonWidgetImpl;
import com.compdfkit.ui.reader.CPDFPageView;
import com.compdfkit.ui.reader.CPDFReaderView;

import java.util.ArrayList;
import java.util.Arrays;

import pub.devrel.easypermissions.AfterPermissionGranted;
import pub.devrel.easypermissions.AppSettingsDialog;
import pub.devrel.easypermissions.EasyPermissions;

public class PDFActivity extends CBasicActivity {

    public static final String EXTRA_FILE_PATH = "file_path";

    /**
     * assets folder pdf file
     */
    public static final String QUICK_START_GUIDE = "PDF32000_2008.pdf";

    private PdfSampleActivityBinding binding;

    CSampleScreenManager screenManager = new CSampleScreenManager();

    private ActivityResultLauncher<Intent> selectDocumentLauncher = registerForActivityResult(new ActivityResultContracts.StartActivityForResult(), result -> {
        if (result.getData() != null && result.getData().getData() != null) {
            CPDFReaderView readerView = binding.pdfView.getCPdfReaderView();
            if (readerView != null && readerView.getEditManager() != null) {
                readerView.getEditManager().endEdit();
            }
            if (readerView.getContextMenuShowListener() != null) {
                readerView.getContextMenuShowListener().dismissContextMenu();
            }
            Uri uri = result.getData().getData();
            CFileUtils.takeUriPermission(this, uri);
            resetContextMenu(binding.pdfView, CPreviewMode.Viewer);
            binding.pdfView.resetAnnotationType();
            binding.formToolBar.reset();
            binding.editToolBar.resetStatus();
            binding.pdfToolBar.selectMode(CPreviewMode.Viewer);
            screenManager.changeWindowStatus(CPreviewMode.Viewer);
            binding.pdfView.openPDF(uri, () -> {
                binding.editToolBar.setEditMode(false);
            });
        }
    });

    private final static int RC_PERMISSION_PERM = 111;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = PdfSampleActivityBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());
        screenManager.bind(binding);
        //Extract PDF files from the Android assets folder
        initPDFView();
        initToolBarView();
        initSearchBar();
        initAnnotToolbar();
        initFormToolbar();
        initEditBar();
        setPreviewMode(CPreviewMode.Viewer);
        onDoNext();
    }

    private void initPDFView() {
        if (getIntent().hasExtra(EXTRA_FILE_PATH)) {
            String path = getIntent().getStringExtra(EXTRA_FILE_PATH);
            binding.pdfView.openPDF(path);
            binding.editToolBar.setEditMode(false);
        }else {
            CExtractAssetFileTask.extract(this, QUICK_START_GUIDE, QUICK_START_GUIDE, (filePath) -> {
                        binding.pdfView.openPDF(filePath);
                        binding.editToolBar.setEditMode(false);
                    }
            );
        }
        binding.pdfView.setAllowAddAndEditAnnot(false);
        binding.pdfView.getCPdfReaderView().setMinScaleEnable(false);
        resetContextMenu(binding.pdfView, CPreviewMode.Viewer);
        initAnnotationAttr(binding.pdfView);
        initFormAttr(binding.pdfView);
        registerAnnotHelper(binding.pdfView);
        registerFormHelper(binding.pdfView);
        binding.pdfView.addOnPDFFocusedTypeChangeListener(type -> {
            if (type != CPDFAnnotation.Type.INK) {
                if (binding.inkCtrlView.getVisibility() == View.VISIBLE) {
                    screenManager.changeWindowStatus(type);
                }
            }
        });
        binding.pdfView.setOnTapMainDocAreaCallback(() -> {
            //Use the CFillScreenManager.class to manage fullscreen switching.
            screenManager.fillScreenChange();
        });
        binding.pdfView.getCPdfReaderView().setPdfAddAnnotCallback((cpdfPageView, cpdfBaseAnnot) -> {
            // Annotation creation completed listener, you can use cpdfBaseAnnot.getAnnotType() to determine the type of the added annotation
            if (cpdfBaseAnnot instanceof CPDFListboxWidgetImpl) {
                // When the ListBox form is created, display an editing dialog for adding list data
                CPDFAnnotationManager annotationManager = new CPDFAnnotationManager();
                annotationManager.showFormListEditFragment(getSupportFragmentManager(), cpdfBaseAnnot, cpdfPageView, false);
            } else if (cpdfBaseAnnot instanceof CPDFComboboxWidgetImpl) {
                // When the ComboBox form is created, display an editing dialog for adding list data
                CPDFAnnotationManager annotationManager = new CPDFAnnotationManager();
                annotationManager.showFormComboBoxEditFragment(getSupportFragmentManager(), cpdfBaseAnnot, cpdfPageView,true);
            } else if (cpdfBaseAnnot instanceof CPDFPushbuttonWidgetImpl) {
                // When the PushButton form is created, display a dialog for editing the action method
                CPDFAnnotationManager annotationManager = new CPDFAnnotationManager();
                annotationManager.showPushButtonActionDialog(getSupportFragmentManager(), binding.pdfView.getCPdfReaderView(),
                        cpdfBaseAnnot, cpdfPageView);
            }
        });
    }

    private void setPreviewMode(CPreviewMode mode) {
        if (binding.pdfView.getCPdfReaderView() == null) {
            return;
        }
        binding.pdfView.getCPdfReaderView().removeAllAnnotFocus();
        IContextMenuShowListener contextMenuShowListener = binding.pdfView.getCPdfReaderView().getContextMenuShowListener();
        if (contextMenuShowListener != null) {
            contextMenuShowListener.dismissContextMenu();
        }
        screenManager.changeWindowStatus(mode);
        binding.pdfToolBar.selectMode(mode);
        binding.formToolBar.reset();
        resetContextMenu(binding.pdfView, mode);
        CPDFEditManager editManager = binding.pdfView.getCPdfReaderView().getEditManager();
        if (mode == CPreviewMode.Edit) {
            if (editManager != null && !editManager.isEditMode()) {
                editManager.beginEdit(CPDFEditType.EDIT_TEXT_IMAGE);
            }
            if (!hasPermissions(STORAGE_PERMISSIONS)){
                EasyPermissions.requestPermissions(this, "request permission", 1234, STORAGE_PERMISSIONS);
            }
        } else {
            if (editManager != null && editManager.isEditMode()) {
                editManager.endEdit();
            }
            switch (mode) {
                case Viewer:
                    binding.pdfView.getCPdfReaderView().setCurrentFocusedFormType(CPDFWidget.WidgetType.Widget_Unknown);
                    binding.pdfView.getCPdfReaderView().setCurrentFocusedType(CPDFAnnotation.Type.UNKNOWN);
                    binding.pdfView.getCPdfReaderView().setTouchMode(CPDFReaderView.TouchMode.BROWSE);
                    binding.pdfView.setAllowAddAndEditAnnot(true);
                    break;
                case Annotation:
                    binding.pdfView.setAllowAddAndEditAnnot(true);
                    binding.pdfView.resetAnnotationType();
                    break;
                case Form:
                    binding.pdfView.getCPdfReaderView().setCurrentFocusedFormType(CPDFWidget.WidgetType.Widget_Unknown);
                    binding.pdfView.getCPdfReaderView().setCurrentFocusedType(CPDFAnnotation.Type.WIDGET);
                    binding.pdfView.getCPdfReaderView().setTouchMode(CPDFReaderView.TouchMode.BROWSE);
                    binding.pdfView.setAllowAddAndEditAnnot(true);
                    break;
                default:
                    break;
            }
        }
    }

    private void initToolBarView() {
        binding.pdfToolBar.addMode(CPreviewMode.Annotation);
        binding.pdfToolBar.addMode(CPreviewMode.Edit);
        binding.pdfToolBar.addMode(CPreviewMode.Form);
        binding.pdfToolBar.setPreviewModeChangeListener(this::setPreviewMode);
        binding.pdfToolBar.setSearchBtnClickListener(v -> {
            if (binding.pdfView.getCPdfReaderView().getEditManager().isEditMode()){
                curEditMode = binding.pdfView.getCPdfReaderView().getLoadType();
            }else {
                curEditMode = CPDFEditType.EDIT_CLOSE;
            }
            binding.pdfView.exitEditMode();
            binding.pdfToolBar.setVisibility(View.GONE);
            binding.pdfSearchToolBar.setVisibility(View.VISIBLE);
            binding.pdfSearchToolBar.showKeyboard();
        });
        binding.pdfToolBar.setThumbnailBtnClickListener(v -> {
            showPageEdit(binding.pdfView, false,()->{
                if (curEditMode > 0 && binding.pdfToolBar.getMode() == CPreviewMode.Edit) {
                    CPDFEditManager editManager = binding.pdfView.getCPdfReaderView().getEditManager();
                    if (!editManager.isEditMode()) {
                        editManager.beginEdit(curEditMode);
                    }
                }
            });
        });
        binding.pdfToolBar.setBoTaBtnClickListener(v -> {
            binding.pdfView.getCPdfReaderView().removeAllAnnotFocus();
            binding.pdfView.exitEditMode();
            ArrayList<CPDFBotaFragmentTabs> tabs = new ArrayList<>();
            CPDFBotaFragmentTabs annotationTab = new CPDFBotaFragmentTabs(CPDFBOTA.ANNOTATION, getString(R.string.tools_annotations));
            CPDFBotaFragmentTabs outlineTab = new CPDFBotaFragmentTabs(CPDFBOTA.OUTLINE, getString(R.string.tools_outlines));
            CPDFBotaFragmentTabs bookmarkTab = new CPDFBotaFragmentTabs(CPDFBOTA.BOOKMARKS, getString(R.string.tools_bookmarks));
            if (binding.pdfToolBar.getMode() == CPreviewMode.Viewer) {
                tabs.add(outlineTab);
                tabs.add(bookmarkTab);
            } else {
                tabs.add(outlineTab);
                tabs.add(bookmarkTab);
                tabs.add(annotationTab);
            }
            CPDFBotaDialogFragment dialogFragment = CPDFBotaDialogFragment.newInstance();
            dialogFragment.initWithPDFView(binding.pdfView);
            dialogFragment.setBotaDialogTabs(tabs);
            dialogFragment.show(getSupportFragmentManager(), "annotationList");
        });
        binding.pdfToolBar.setMoreBtnClickListener(v -> {
            v.setSelected(true);
            //Show the PDF settings dialog fragment
            CPopupMenuWindow menuWindow = new CPopupMenuWindow(this);
            menuWindow.addItem(R.drawable.tools_ic_preview_settings, R.string.tools_view_setting, v1 -> {
                showDisplaySettings(binding.pdfView);
            });
            menuWindow.addItem(R.drawable.tools_page_edit, R.string.tools_page_edit_toolbar_title, v1 -> {
                showPageEdit(binding.pdfView, true,()->{
                    if (curEditMode > 0 && binding.pdfToolBar.getMode() == CPreviewMode.Edit) {
                        CPDFEditManager editManager = binding.pdfView.getCPdfReaderView().getEditManager();
                        if (!editManager.isEditMode()) {
                            editManager.beginEdit(curEditMode);
                        }
                    }
                });
            });
            menuWindow.addItem(R.drawable.tools_ic_document_info, R.string.tools_document_info, v1 -> {
                showDocumentInfo(binding.pdfView);
            });
            menuWindow.addItem(R.drawable.tools_ic_share, R.string.tools_share, v1 -> {
                sharePDF(binding.pdfView);
            });
            menuWindow.addItem(R.drawable.tools_ic_new_file, R.string.tools_open_document, v1 -> {
                if (hasPermissions(STORAGE_PERMISSIONS)) {
                    selectDocument();
                } else {
                    requestStoragePermissions();
                }
            });
            menuWindow.setOnDismissListener(() -> v.setSelected(false));
            menuWindow.showAsDropDown(v);
        });
    }

    private void requestStoragePermissions(){
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU){
            startActivity(new Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION));
        }else {
            EasyPermissions.requestPermissions(this, "request permission", REQUEST_EXTERNAL_PERMISSION, STORAGE_PERMISSIONS);
        }
    }

    private void initAnnotToolbar() {
        binding.annotationToolBar.initWithPDFView(binding.pdfView);
        binding.annotationToolBar.setFragmentManager(getSupportFragmentManager());
        binding.annotationToolBar.setAnnotationChangeListener(type -> {
            screenManager.changeWindowStatus(type);
            //You are required to grant recording permission when selecting voice notes
            if (type == CAnnotationType.SOUND) {
                if (!EasyPermissions.hasPermissions(this, Manifest.permission.RECORD_AUDIO)) {
                    EasyPermissions.requestPermissions(this, getString(R.string.tools_use_sound_annot), 112, Manifest.permission.RECORD_AUDIO);
                }
            }
        });
        binding.inkCtrlView.initWithPDFView(binding.pdfView);
        binding.inkCtrlView.setFragmentManager(getSupportFragmentManager());
    }

    private void initFormToolbar() {
        binding.formToolBar.initWithPDFView(binding.pdfView);
        binding.formToolBar.setFragmentManager(getSupportFragmentManager());
    }

    private void initSearchBar() {
        binding.pdfSearchToolBar.initWithPDFView(binding.pdfView);
        binding.pdfSearchToolBar.onSearchQueryResults(list -> {
            CSearchResultDialogFragment searchResultDialog = new CSearchResultDialogFragment();
            searchResultDialog.show(getSupportFragmentManager(), "searchResultDialogFragment");
            searchResultDialog.setSearchTextInfos(list);
            searchResultDialog.setOnClickSearchItemListener(clickItem -> {
                binding.pdfView.getCPdfReaderView().setDisplayPageIndex(clickItem.page);
                binding.pdfView.getCPdfReaderView().getTextSearcher().searchBegin(clickItem.page, clickItem.textRangeIndex);
                searchResultDialog.dismiss();
            });
        });
        binding.pdfSearchToolBar.setExitSearchListener(() -> {
            if (curEditMode > 0) {
                CPDFEditManager editManager = binding.pdfView.getCPdfReaderView().getEditManager();
                if (!editManager.isEditMode()) {
                    editManager.beginEdit(curEditMode);
                }
            }
            binding.pdfToolBar.setVisibility(View.VISIBLE);
            binding.pdfSearchToolBar.setVisibility(View.GONE);
        });
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == REQUEST_EXTERNAL_PERMISSION) {
            if (hasPermissions(STORAGE_PERMISSIONS)) {
                selectDocument();
            }
        } else if (requestCode == 112) {
            if (!EasyPermissions.hasPermissions(this, permissions)) {
                if (EasyPermissions.somePermissionPermanentlyDenied(this, Arrays.asList(permissions))) {
                    new AppSettingsDialog.Builder(this)
                            .build().show();
                }else {
                    binding.pdfView.resetAnnotationType();
                }
            }
        } else if (requestCode == AppSettingsDialog.DEFAULT_SETTINGS_REQ_CODE) {
            if (!EasyPermissions.hasPermissions(this, permissions)) {
                binding.pdfView.resetAnnotationType();
            }
        }
    }

    private void initEditBar() {
        if (binding.pdfView == null || binding.pdfView.getCPdfReaderView() == null) {
            return;
        }
        binding.editToolBar.initWithPDFView(binding.pdfView);
        binding.editToolBar.setEditPropertyBtnClickListener((view) -> {
            int type = binding.pdfView.getCPdfReaderView().getSelectAreaType();
            CStyleType styleType = CStyleType.UNKNOWN;
            if (type == SELECT_AREA_TEXT) {
                styleType = CStyleType.EDIT_TEXT;
            } else if (type == SELECT_AREA_IMAGE) {
                styleType = CStyleType.EDIT_IMAGE;
            }
            if (styleType != CStyleType.UNKNOWN) {
                CPDFReaderView readerView = binding.pdfView.getCPdfReaderView();
                CPDFContextMenuHelper menuHelper = (CPDFContextMenuHelper) readerView.getContextMenuShowListener();
                if (menuHelper == null || menuHelper.getReaderView() == null) {
                    return;
                }
                CStyleManager styleManager = new CStyleManager(menuHelper.getEditSelection(), menuHelper.getPageView());
                CAnnotStyle annotStyle = styleManager.getStyle(styleType);
                CStyleDialogFragment styleDialogFragment = CStyleDialogFragment.newInstance(annotStyle);
                styleManager.setAnnotStyleFragmentListener(styleDialogFragment);
                styleManager.setDialogHeightCallback(styleDialogFragment, binding.pdfView.getCPdfReaderView());
                styleDialogFragment.show(getSupportFragmentManager(), "textPropertyDialogFragment");
                menuHelper.dismissContextMenu();
            }
        });
        binding.pdfView.setEndScrollCallback(() -> {
            binding.editToolBar.updateUndoRedo();
        });
    }

    private void selectDocument() {
        if (binding.pdfToolBar.getMode() == CPreviewMode.Edit) {
            binding.pdfView.exitEditMode();
        }
        if (!binding.pdfView.getCPdfReaderView().getPDFDocument().hasChanges()) {
            selectDocumentLauncher.launch(CFileUtils.getContentIntent());
            return;
        }
        CAlertDialog alertDialog = CAlertDialog.newInstance(getString(com.compdfkit.tools.R.string.tools_save_title), getString(com.compdfkit.tools.R.string.tools_save_message));
        alertDialog.setConfirmClickListener(v -> {
            //save pdf document
            binding.pdfView.savePDF((filePath, pdfUri) -> {
                alertDialog.dismiss();
                selectDocumentLauncher.launch(CFileUtils.getContentIntent());
            });
        });
        alertDialog.setCancelClickListener(v -> {
            alertDialog.dismiss();
            selectDocumentLauncher.launch(CFileUtils.getContentIntent());
        });
        alertDialog.show(getSupportFragmentManager(), "alertDialog");
    }

    @AfterPermissionGranted(RC_PERMISSION_PERM)
    private void onDoNext() {
        if (!hasPermissions()) {
            EasyPermissions.requestPermissions(this, getString(R.string.app_permission_storage), RC_PERMISSION_PERM, STORAGE_PERMISSIONS);
        }
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == ReplaceEditImageArea) {
            if (binding.pdfView == null || binding.pdfView.getCPdfReaderView() == null) {
                return;
            }
            for (int i = 0; i < binding.pdfView.getCPdfReaderView().getChildCount(); i++) {
                CPDFPageView pageView = (CPDFPageView) binding.pdfView.getCPdfReaderView().getChildAt(i);
                if (pageView == null) {
                    continue;
                }
                if (data == null) {
                    return;
                }
                if (pageView.getPageNum() == binding.pdfView.getCPdfReaderView().getPageNum()) {
                    String imagePath = CUriUtil.copyUriToInternalCache(this, data.getData());
                    boolean ret = pageView.operateEditImageArea(CPDFPageView.EditImageFuncType.REPLACE, imagePath);
                    if (ret == false) {
                        Toast.makeText(getApplicationContext(), "replace fail", Toast.LENGTH_LONG).show();
                    }
                    break;
                }
            }
        } else if (requestCode == AddEditImageArea) {
            if (binding.pdfView == null || binding.pdfView.getCPdfReaderView() == null) {
                return;
            }
            if (data == null) {
                return;
            }
            for (int i = 0; i < binding.pdfView.getCPdfReaderView().getChildCount(); i++) {
                CPDFPageView pageView = (CPDFPageView) binding.pdfView.getCPdfReaderView().getChildAt(i);
                if (pageView == null) {
                    continue;
                }
                if (pageView.getPageNum() == binding.pdfView.getCPdfReaderView().getAddImagePage()) {
                    String imagePath = CUriUtil.copyUriToInternalCache(this, data.getData());
                    boolean ret = pageView.addEditImageArea(binding.pdfView.getCPdfReaderView().getAddImagePoint(), imagePath);
                    if (ret == false) {
                        Toast.makeText(getApplicationContext(), "add fail", Toast.LENGTH_LONG).show();
                    }
                    break;
                }
            }
        }
    }


    @Override
    public void onBackPressed() {
        if (binding.pdfView != null) {
            binding.pdfView.savePDF((filePath, pdfUri) -> super.onBackPressed());
        }
    }
}