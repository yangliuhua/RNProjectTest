//
//  CPDFViewController.m
//   PDFView_RN
//
//  Copyright © 2014-2023 PDF Technologies, Inc. All Rights Reserved.
//
//  THIS SOURCE CODE AND ANY ACCOMPANYING DOCUMENTATION ARE PROTECTED BY INTERNATIONAL COPYRIGHT LAW
//  AND MAY NOT BE RESOLD OR REDISTRIBUTED. USAGE IS BOUND TO THE ComPDFKit LICENSE AGREEMENT.
//  UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS SUBJECT TO CIVIL AND CRIMINAL PENALTIES.
//  This notice may not be removed from this file.
//

#import "CPDFViewController.h"

#import <ComPDFKit/ComPDFKit.h>
#import <ComPDFKit_Tools/ComPDFKit_Tools.h>
#import <AVFAudio/AVFAudio.h>
#import <AVFoundation/AVFoundation.h>

@interface CPDFViewController () <CPDFSoundPlayBarDelegate,CPDFAnnotationBarDelegate,CPDFToolsViewControllerDelegate,CPDFNoteOpenViewControllerDelegate,CPDFBOTAViewControllerDelegate,CPDFEditToolBarDelegate,CPDFFormBarDelegate,CPDFListViewDelegate,CPDFSignatureViewControllerDelegate,CPDFPageEditViewControllerDelegate,CPDFKeyboardToolbarDelegate>

@property(nonatomic, strong) CPDFAnnotationToolBar *annotationBar;

@property (nonatomic, strong) CPDFFormToolBar *formBar;

@property(nonatomic, strong) CPDFSoundPlayBar *soundPlayBar;

@property(nonatomic, strong) CAnnotationManage *annotationManage;

@property(nonatomic, strong) CPDFEditToolBar * toolBar;

@property(nonatomic, strong) CPDFEditViewController *baseVC;

@property(nonatomic, assign) CPDFEditMode editMode;

@property(nonatomic, strong) CPDFSignatureWidgetAnnotation * signatureAnnotation;

@end

@implementation CPDFViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
   self.pdfListView.toolModel = CToolModelViewer;
    
    CPDFEditingConfig *editingConfig = [[CPDFEditingConfig alloc]init];
    editingConfig.editingBorderWidth = 1.0;
    editingConfig.editingOffsetGap = 5;
    self.pdfListView.editingConfig = editingConfig;
    
    [self initAnnotationBar];
    [self initWithEditTool];
    [self initWithFormTool];

    [self enterViewerMode];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(PDFPageDidRemoveAnnotationNotification:) name:CPDFPageDidRemoveAnnotationNotification object:nil];
}

- (void)initAnnotationBar {
    self.annotationManage = [[CAnnotationManage alloc] initWithPDFView:self.pdfListView];
        
    self.annotationBar = [[CPDFAnnotationToolBar alloc] initAnnotationManage:self.annotationManage];
    
    CGFloat height = 44.0;
    if (@available(iOS 11.0, *))
        height += self.view.safeAreaInsets.bottom;
    
    self.annotationBar.frame = CGRectMake(0, self.view.frame.size.height - height, self.view.frame.size.width, height);
    self.annotationBar.delegate = self;
    [self.annotationBar setParentVC:self];
    [self.view addSubview:self.annotationBar];
}

- (void)initWithEditTool {
    if(!self.toolBar){
        self.toolBar = [[CPDFEditToolBar alloc] initWithPDFView:self.pdfListView];
    }
    
    self.toolBar.delegate = self;
    [self.view addSubview:self.toolBar];
}

- (void)initWithFormTool {
    if(!self.formBar){
        self.formBar = [[CPDFFormToolBar  alloc] initAnnotationManage:self.annotationManage];
    }
    self.formBar.delegate = self;
    self.formBar.parentVC = self;
    [self.view addSubview:self.formBar];
}

- (void)initWitNavigationTitle {
    //titleButton
    CNavigationBarTitleButton * navTitleButton = [[CNavigationBarTitleButton alloc] init];
    self.titleButton = navTitleButton;
    self.navigationTitle = NSLocalizedString(@"View", nil);
    [navTitleButton setImage:[UIImage imageNamed:@"syasarrow"] forState:UIControlStateNormal];
    [navTitleButton addTarget:self action:@selector(titleButtonClickd:) forControlEvents:UIControlEventTouchUpInside];
    [navTitleButton setTitle:self.navigationTitle forState:UIControlStateNormal];
    [navTitleButton setTitleColor:[CPDFColorUtils CAnyReverseBackgooundColor] forState:UIControlStateNormal];
    self.titleButton.frame = CGRectMake(0, 0, 50, 30);
    self.navigationItem.titleView = self.titleButton;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    if([self.popMenu superview]) {
        if (@available(iOS 11.0, *)) {
            [self.popMenu showMenuInRect:CGRectMake(self.view.frame.size.width - self.view.safeAreaInsets.right - 250, CGRectGetMaxY(self.navigationController.navigationBar.frame), 250, 250)];
        } else {
            // Fallback on earlier versions
            [self.popMenu showMenuInRect:CGRectMake(self.view.frame.size.width - 250, CGRectGetMaxY(self.navigationController.navigationBar.frame), 250, 250)];
        }
    }
    
    CGFloat height = 44.0;
    
    if (@available(iOS 11.0, *))
        height += self.view.safeAreaInsets.bottom;

    CGFloat bottomHeight = 0;
    if(CToolModelAnnotation == self.pdfListView.toolModel) {
        self.annotationBar.frame = CGRectMake(0, self.view.frame.size.height - height, self.view.frame.size.width, height);
        bottomHeight = self.self.annotationBar.frame.size.height;
    } else if(CToolModelEdit == self.pdfListView.toolModel){
        self.toolBar.frame = CGRectMake(0, self.view.frame.size.height - height, self.view.frame.size.width, height);
        bottomHeight = self.self.toolBar.frame.size.height;
    } else if(CToolModelForm == self.pdfListView.toolModel){
        self.formBar.frame = CGRectMake(0, self.view.frame.size.height - height, self.view.frame.size.width, height);
        bottomHeight = self.self.formBar.frame.size.height;
    }
    
    CGFloat tPosY = 0;
    CGFloat tBottomY = 0;

    if(CToolModelAnnotation == self.pdfListView.toolModel) {
        if (!self.navigationController.navigationBarHidden) {
            [UIView animateWithDuration:0.3 animations:^{
                CGRect frame = self.annotationBar.frame;
                frame.origin.y = self.view.bounds.size.height-frame.size.height;
                self.annotationBar.frame = frame;
            }];
            CGRect rectStatus = [[UIApplication sharedApplication] statusBarFrame];
            tPosY = self.navigationController.navigationBar.frame.size.height + rectStatus.size.height;
            
            tBottomY = self.annotationBar.frame.size.height;
        } else {
            [UIView animateWithDuration:0.3 animations:^{
                CGRect frame = self.annotationBar.frame;
                frame.origin.y = self.view.bounds.size.height;
                self.annotationBar.frame = frame;
            }];
        }
    } else {
        tPosY = 0;
        if (!self.navigationController.navigationBarHidden) {
            CGRect rectStatus = [[UIApplication sharedApplication] statusBarFrame];
            tPosY = self.navigationController.navigationBar.frame.size.height + rectStatus.size.height;
        }
    }
    
    
    if (CPDFDisplayDirectionVertical == [CPDFKitConfig  sharedInstance].displayDirection) {
            UIEdgeInsets inset = self.pdfListView.documentView.contentInset;
            inset.bottom = 10 + bottomHeight;
            self.pdfListView.documentView.contentInset = inset;
    } else{
        UIEdgeInsets inset = self.pdfListView.documentView.contentInset;
            inset.bottom = 0;
            self.pdfListView.documentView.contentInset = inset;
    }
}

#pragma mark - Public Methods

- (void)selectDocumentRefresh {
    if(CToolModelAnnotation == self.pdfListView.toolModel) {
        self.pdfListView.annotationMode = CPDFViewAnnotationModeNone;
        [self.annotationBar updatePropertiesButtonState];
        [self.annotationBar reloadData];
        [self.annotationBar updateUndoRedoState];
    }else if(CToolModelForm == self.pdfListView.toolModel) {
        [self.formBar initUndoRedo];
    }
}

#pragma mark - Private

- (void)enterEditMode {
    [self selectDocumentRefresh];

    self.toolBar.hidden = NO;
    self.annotationBar.hidden = YES;
    self.formBar.hidden = YES;
    self.pdfListView.toolModel = CToolModelEdit;
    [self.pdfListView beginEditingLoadType:CEditingLoadTypeText | CEditingLoadTypeImage];
    self.navigationTitle = NSLocalizedString(@"Content Edit", nil);
    [self.titleButton setTitle:self.navigationTitle forState:UIControlStateNormal];
    
    [self.toolBar updateButtonState];
    
    CGRect frame = self.toolBar.frame;
    frame.origin.y = self.view.bounds.size.height-frame.size.height;
    self.toolBar.frame = frame;
    
    [self viewWillLayoutSubviews];
}

- (void)enterAnnotationMode {
    self.toolBar.hidden = YES;
    self.annotationBar.hidden = NO;
    self.formBar.hidden = YES;
    if (self.pdfListView.isEdited) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.pdfListView commitEditing];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.pdfListView endOfEditing];
            });
        });
    } else {
        [self.pdfListView endOfEditing];
    }
    self.pdfListView.toolModel = CToolModelAnnotation;
    self.navigationTitle = NSLocalizedString(@"Annotation", nil);
    [self.titleButton setTitle:self.navigationTitle forState:UIControlStateNormal];
    
    CGFloat tPosY = 0;
    CGFloat tBottomY = 0;
    CGRect frame = self.annotationBar.frame;
    frame.origin.y = self.view.bounds.size.height-frame.size.height;
    self.annotationBar.frame = frame;
    
    CGRect rectStatus = [[UIApplication sharedApplication] statusBarFrame];
    tPosY = self.navigationController.navigationBar.frame.size.height + rectStatus.size.height;
    tBottomY = self.annotationBar.frame.size.height;
    
    if (CPDFDisplayDirectionVertical == [CPDFKitConfig  sharedInstance].displayDirection) {
            UIEdgeInsets inset = self.pdfListView.documentView.contentInset;
            inset.bottom = 10 + self.annotationBar.frame.size.height;
            self.pdfListView.documentView.contentInset = inset;
    } else{
            UIEdgeInsets inset = self.pdfListView.documentView.contentInset;
            inset.bottom = 0;
            self.pdfListView.documentView.contentInset = inset;
    }

    [self viewWillLayoutSubviews];
}

- (void)enterViewerMode {
    self.toolBar.hidden = YES;
    self.formBar.hidden = YES;
    self.annotationBar.hidden = YES;
    if (self.pdfListView.isEdited) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.pdfListView commitEditing];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.pdfListView endOfEditing];
            });
        });
    } else {
        [self.pdfListView endOfEditing];
    }
    self.pdfListView.toolModel = CToolModelViewer;
    self.navigationTitle = NSLocalizedString(@"Viewer", nil);
    [self.titleButton setTitle:self.navigationTitle forState:UIControlStateNormal];

    CGRect frame = self.annotationBar.frame;
    frame.origin.y = self.view.bounds.size.height;
    self.annotationBar.frame = frame;

    if (CPDFDisplayDirectionVertical == [CPDFKitConfig  sharedInstance].displayDirection) {
            UIEdgeInsets inset = self.pdfListView.documentView.contentInset;
            inset.bottom = 0;
            self.pdfListView.documentView.contentInset = inset;
    } else{
            UIEdgeInsets inset = self.pdfListView.documentView.contentInset;
            inset.bottom = 0;
            self.pdfListView.documentView.contentInset = inset;
    }

}

- (void)enterFormMode {
    self.toolBar.hidden = YES;
    self.annotationBar.hidden = YES;
    self.formBar.hidden = NO;
    if (self.pdfListView.isEdited) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.pdfListView commitEditing];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.pdfListView endOfEditing];
            });
        });
    } else {
        [self.pdfListView endOfEditing];
    }
    self.pdfListView.toolModel = CToolModelForm;
    self.navigationTitle = NSLocalizedString(@"Form", nil);
    [self.titleButton setTitle:self.navigationTitle forState:UIControlStateNormal];

    CGFloat tPosY = 0;
    CGFloat tBottomY = 0;
    CGRect frame = self.formBar.frame;
    frame.origin.y = self.view.bounds.size.height-frame.size.height;
    self.formBar.frame = frame;

    CGRect rectStatus = [[UIApplication sharedApplication] statusBarFrame];
    tPosY = self.navigationController.navigationBar.frame.size.height + rectStatus.size.height;
    tBottomY = self.formBar.frame.size.height;

    if (CPDFDisplayDirectionVertical == [CPDFKitConfig  sharedInstance].displayDirection) {
        UIEdgeInsets inset = self.pdfListView.documentView.contentInset;
        inset.bottom = 10 + self.formBar.frame.size.height;
        self.pdfListView.documentView.contentInset = inset;
    } else{
        UIEdgeInsets inset = self.pdfListView.documentView.contentInset;
        inset.bottom = 0;
        self.pdfListView.documentView.contentInset = inset;
    }
    [self viewWillLayoutSubviews];
}

- (void)setTitleRefresh {
    if (CToolModelEdit == self.pdfListView.toolModel) {
        [self enterEditMode];
    } else if (CToolModelViewer == self.pdfListView.toolModel) {
        [self enterViewerMode];
    } else if (CToolModelAnnotation == self.pdfListView.toolModel) {
        [self enterAnnotationMode];
    } else if(CToolModelForm == self.pdfListView.toolModel) {
        [self enterFormMode];
    }
}

#pragma mark - Action

- (void)navigationRightItemBota {
    CPDFBOTAViewController *botaViewController = [[CPDFBOTAViewController alloc] initCustomizeWithPDFView:self.pdfListView navArrays:@[@(CPDFBOTATypeStateOutline),@(CPDFBOTATypeStateBookmark),@(CPDFBOTATypeStateAnnotation)]];

    botaViewController.delegate = self;
    
    AAPLCustomPresentationController *presentationController NS_VALID_UNTIL_END_OF_SCOPE;
   
    presentationController = [[AAPLCustomPresentationController alloc] initWithPresentedViewController:botaViewController presentingViewController:self];
    botaViewController.transitioningDelegate = presentationController;
    
    [self presentViewController:botaViewController animated:YES completion:nil];
}

- (void) titleButtonClickd:(UIButton *) button {
    CPDFToolsViewController * toolsVc = [[CPDFToolsViewController alloc] initCustomizeWithToolArrays:@[@(CToolModelViewer),@(CToolModelEdit),@(CToolModelAnnotation),@(CToolModelForm)]];
    toolsVc.delegate = self;
    AAPLCustomPresentationController *presentationController NS_VALID_UNTIL_END_OF_SCOPE;
    presentationController = [[AAPLCustomPresentationController alloc] initWithPresentedViewController:toolsVc presentingViewController:self];
    toolsVc.transitioningDelegate = presentationController;
    [self presentViewController:toolsVc animated:YES completion:nil];
}

#pragma - CPDFEditToolBarDelegate

- (void)undoDidClickInToolBar:(CPDFEditToolBar *)toolBar{
    [self.pdfListView editTextUndo];
}

- (void)redoDidClickInToolBar:(CPDFEditToolBar *)toolBar{
    [self.pdfListView editTextRedo];
}

- (void)propertyEditDidClickInToolBar:(CPDFEditToolBar *)toolBar{
    [self showMenuList];
}


- (void)showMenuList {
    _baseVC = [[CPDFEditViewController alloc] initWithPDFView:self.pdfListView];
    _baseVC.editMode = self.editMode;
    if((self.editMode == CPDFEditModeText || self.editMode == CPDFEditModeImage) && self.pdfListView.editStatus != CEditingSelectStateEmpty){
        
        AAPLCustomPresentationController *presentationController NS_VALID_UNTIL_END_OF_SCOPE;
       
        presentationController = [[AAPLCustomPresentationController alloc] initWithPresentedViewController:self.baseVC presentingViewController:self];
        self.baseVC.transitioningDelegate = presentationController;
        
        [self presentViewController:self.baseVC animated:YES completion:nil];
    }
}

#pragma mark - CPDFViewDelegate

- (void)PDFViewEditingSelectStateDidChanged:(CPDFView *)pdfView {
    if([pdfView.editingArea isKindOfClass:[CPDFEditImageArea class]]) {
        self.editMode = CPDFEditModeImage;
    }else if([pdfView.editingArea isKindOfClass:[CPDFEditTextArea class]]) {
        self.editMode  = CPDFEditModeText;
    }
    
    [self.toolBar updateButtonState];
}

- (void)PDFViewShouldBeginEditing:(CPDFView *)pdfView textView:(UITextView *)textView forAnnotation:(CPDFFreeTextAnnotation *)annotation {
    CPDFKeyboardToolbar *keyBoadrdToolbar = [[CPDFKeyboardToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 50)];
    keyBoadrdToolbar.delegate = self;
    [keyBoadrdToolbar bindToTextView:textView];
}

#pragma mark - CPDFListViewDelegate

- (void)PDFListViewPerformTouchEnded:(CPDFListView *)pdfView {
    CGFloat tPosY = 0;
    CGFloat tBottomY = 0;

    if(CToolModelAnnotation == self.pdfListView.toolModel) {
        if (self.navigationController.navigationBarHidden) {
            [self.navigationController setNavigationBarHidden:NO animated:YES];
            [UIView animateWithDuration:0.3 animations:^{
                CGRect frame = self.annotationBar.frame;
                frame.origin.y = self.view.bounds.size.height-frame.size.height;
                self.annotationBar.frame = frame;
                self.pdfListView.pageSliderView.alpha = 1.0;
                self.annotationBar.topToolBar.alpha = 1.0;
                self.annotationBar.drawPencilFuncView.alpha = 1.0;
            }];
            CGRect rectStatus = [[UIApplication sharedApplication] statusBarFrame];
            tPosY = self.navigationController.navigationBar.frame.size.height + rectStatus.size.height;
            
            tBottomY = self.annotationBar.frame.size.height;
        } else {
            [self.navigationController setNavigationBarHidden:YES animated:YES];
            [UIView animateWithDuration:0.3 animations:^{
                CGRect frame = self.annotationBar.frame;
                frame.origin.y = self.view.bounds.size.height;
                self.annotationBar.frame = frame;
                self.pdfListView.pageSliderView.alpha = 0.0;
                self.annotationBar.topToolBar.alpha = 0.0;
                self.annotationBar.drawPencilFuncView.alpha = 0.0;

            }];
        }
    } else {
        CGFloat tPosY = 0;
        if (self.navigationController.navigationBarHidden) {
            [self.navigationController setNavigationBarHidden:NO animated:YES];
            [UIView animateWithDuration:0.3 animations:^{
                self.pdfListView.pageSliderView.alpha = 1.0;
            }];
            CGRect rectStatus = [[UIApplication sharedApplication] statusBarFrame];
            tPosY = self.navigationController.navigationBar.frame.size.height + rectStatus.size.height;

        } else {
            [self.navigationController setNavigationBarHidden:YES animated:YES];
            [UIView animateWithDuration:0.3 animations:^{
                self.pdfListView.pageSliderView.alpha = 0.0;
            }];
        }
    }
    
    if (CPDFDisplayDirectionVertical == [CPDFKitConfig  sharedInstance].displayDirection) {
            UIEdgeInsets inset = self.pdfListView.documentView.contentInset;
            inset.bottom = 10 + self.annotationBar.frame.size.height;
            self.pdfListView.documentView.contentInset = inset;
    } else{
            UIEdgeInsets inset = self.pdfListView.documentView.contentInset;
            inset.bottom = 0;
            self.pdfListView.documentView.contentInset = inset;
    }
}

- (void)PDFListViewEditNote:(CPDFListView *)pdfListView forAnnotation:(CPDFAnnotation *)annotation {
    if([annotation isKindOfClass:[CPDFLinkAnnotation class]]) {
        [self.annotationBar buttonItemClicked_openAnnotation:self.titleButton];
    } else if ([annotation isKindOfClass:[CPDFWidgetAnnotation class]]) {
        [self.formBar buttonItemClicked_openOption:annotation];
    } else {
        CGRect rect = [self.pdfListView convertRect:annotation.bounds fromPage:annotation.page];
        CPDFNoteOpenViewController *noteVC = [[CPDFNoteOpenViewController alloc]initWithAnnotation:annotation];
        noteVC.delegate = self;
        [noteVC showViewController:self inRect:rect];
    }
}

- (void)PDFListViewChangedAnnotationType:(CPDFListView *)pdfListView forAnnotationMode:(CPDFViewAnnotationMode)annotationMode {
    if(CToolModelAnnotation == self.pdfListView.toolModel) {
        [self.annotationBar reloadData];
    }else if(CToolModelForm == self.pdfListView.toolModel) {
        [self.formBar reloadData];
    }
}

- (void)PDFListViewPerformUrl:(CPDFListView *)pdfView withContent:(NSString *)content {
    NSURL * url = [NSURL URLWithString:content];
    [[UIApplication sharedApplication] openURL:url];
}

- (void)PDFListViewPerformAddStamp:(CPDFListView *)pdfView atPoint:(CGPoint)point forPage:(CPDFPage *)page {
    [self.annotationBar addStampAnnotationWithPage:page point:point];
}

- (void)PDFListViewPerformAddImage:(CPDFListView *)pdfView atPoint:(CGPoint)point forPage:(CPDFPage *)page {
    [self.annotationBar addImageAnnotationWithPage:page point:point];
}

- (BOOL)PDFListViewerTouchEndedIsAudioRecordMedia:(CPDFListView *)pdfListView {
    if (CPDFMediaStateAudioRecord == [CPDFMediaManager shareManager].mediaState) {
        [self PDFListViewPerformTouchEnded:self.pdfListView];
        return YES;
    }
    return NO;
}

- (void)PDFListViewPerformCancelMedia:(CPDFListView *)pdfView atPoint:(CGPoint)point forPage:(CPDFPage *)page {
    [CPDFMediaManager shareManager].mediaState = CPDFMediaStateStop;
}

- (void)PDFListViewPerformRecordMedia:(CPDFListView *)pdfView atPoint:(CGPoint)point forPage:(CPDFPage *)page {
    if([self.soundPlayBar superview]) {
        if(self.soundPlayBar.soundState == CPDFSoundStatePlay) {
            [self.soundPlayBar stopAudioPlay];
            [self.soundPlayBar removeFromSuperview];
        } else if (self.soundPlayBar.soundState == CPDFSoundStateRecord) {
            [self.soundPlayBar stopRecord];
            [self.soundPlayBar removeFromSuperview];
        }
    }
    
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (authStatus == AVAuthorizationStatusNotDetermined || authStatus == AVAuthorizationStatusDenied) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
            if (granted) {
                
            } else {
                NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                if ([[UIApplication sharedApplication] canOpenURL:url]) {
                    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
                }
            }
        }];
    }
    
    if (authStatus == AVAuthorizationStatusAuthorized) {
        NSInteger pageindex = [self.pdfListView.document indexForPage:page];
        [CPDFMediaManager shareManager].mediaState = CPDFMediaStateAudioRecord;
        [CPDFMediaManager shareManager].pageNum = pageindex;
        [CPDFMediaManager shareManager].ptInPdf = point;
        
        _soundPlayBar = [[CPDFSoundPlayBar alloc] initWithStyle:self.annotationManage.annotStyle];
        _soundPlayBar.delegate = self;
        [_soundPlayBar showInView:self.pdfListView soundState:CPDFSoundStateRecord];
        [_soundPlayBar startAudioRecord];
       
    } else {
        return;
    }
}

- (void)PDFListViewPerformPlay:(CPDFListView *)pdfView forAnnotation:(CPDFSoundAnnotation *)annotation {
    NSString *filePath = [annotation mediaPath];
    if (filePath) {
        NSURL *URL = [NSURL fileURLWithPath:filePath];
        
        _soundPlayBar = [[CPDFSoundPlayBar alloc] initWithStyle:self.annotationManage.annotStyle];
        _soundPlayBar.delegate = self;
        [_soundPlayBar showInView:self.pdfListView soundState:CPDFSoundStatePlay];
        [_soundPlayBar setURL:URL];
        [_soundPlayBar startAudioPlay];
        [CPDFMediaManager shareManager].mediaState = CPDFMediaStateVedioPlaying;
    }
}

- (void)PDFListViewPerformSignatureWidget:(CPDFListView *)pdfView forAnnotation:(CPDFSignatureWidgetAnnotation *)annotation {
    if(CToolModelAnnotation == self.pdfListView.toolModel) {
        [self.annotationBar openSignatureAnnotation:annotation];
    }else if(CToolModelViewer == self.pdfListView.toolModel) {
        self.signatureAnnotation = annotation;
        AAPLCustomPresentationController *presentationController NS_VALID_UNTIL_END_OF_SCOPE;
        CPDFSignatureViewController *signatureVC = [[CPDFSignatureViewController alloc] initWithStyle:nil];
        presentationController = [[AAPLCustomPresentationController alloc] initWithPresentedViewController:signatureVC presentingViewController:self];
        signatureVC.delegate = self;
        signatureVC.transitioningDelegate = presentationController;
        [self presentViewController:signatureVC animated:YES completion:nil];
    }
}

- (void)PDFListViewEditProperties:(CPDFListView *)pdfListView forAnnotation:(CPDFAnnotation *)annotation {
    if(CToolModelAnnotation == self.pdfListView.toolModel){
        [self.annotationBar buttonItemClicked_openAnnotation:self.titleButton];
    }else if(CToolModelForm == self.pdfListView.toolModel) {
        [self.formBar buttonItemClicked_open:annotation];
    }
}

- (void)PDFListViewContentEditProperty:(CPDFListView *)pdfView point:(CGPoint)point {
    if([pdfView.editingArea isKindOfClass:[CPDFEditImageArea class]]) {
        self.editMode = CPDFEditModeImage;
    } else if([pdfView.editingArea isKindOfClass:[CPDFEditTextArea class]]) {
        self.editMode  = CPDFEditModeText;
    }
    [self showMenuList];
    [self.toolBar updateButtonState];
}

- (void)PDFViewCurrentPageDidChanged:(CPDFView *)pdfView {
    if([pdfView.editingArea isKindOfClass:[CPDFEditImageArea class]]) {
        self.editMode = CPDFEditModeImage;
    }else if([pdfView.editingArea isKindOfClass:[CPDFEditTextArea class]]) {
        self.editMode  = CPDFEditModeText;
    }
    
    [self.toolBar updateButtonState];
    [super PDFViewCurrentPageDidChanged:pdfView];
}

#pragma mark - CPDFKeyboardToolbarDelegate

- (void)keyboardShouldDissmiss:(CPDFKeyboardToolbar *)toolbar {
    [self.pdfListView commitEditAnnotationFreeText];
    self.pdfListView.annotationMode = CPDFViewAnnotationModeNone;
    [self.annotationBar reloadData];
}

#pragma mark - CPDFAnnotationBarDelegate

- (void)annotationBarClick:(CPDFAnnotationToolBar *)annotationBar clickAnnotationMode:(CPDFViewAnnotationMode)annotationMode forSelected:(BOOL)isSelected forButton:(UIButton *)button {
    if(CPDFViewAnnotationModeInk == annotationMode || CPDFViewAnnotationModePencilDrawing == annotationMode) {
        CGFloat tPosY = 0;
        if(isSelected) {
            [self.navigationController setNavigationBarHidden:YES animated:YES];
            [UIView animateWithDuration:0.3 animations:^{
                CGRect frame = self.annotationBar.frame;
                frame.origin.y = self.view.bounds.size.height;
                self.annotationBar.frame = frame;
                self.pdfListView.pageSliderView.alpha = 0.0;
                
                UIEdgeInsets inset = self.pdfListView.documentView.contentInset;
                inset.bottom = 0;
                self.pdfListView.documentView.contentInset = inset;
            }];
        } else {
            [self.navigationController setNavigationBarHidden:NO animated:YES];
            [UIView animateWithDuration:0.3 animations:^{
                CGRect frame = self.annotationBar.frame;
                frame.origin.y = self.view.bounds.size.height-frame.size.height;
                self.annotationBar.frame = frame;
                self.pdfListView.pageSliderView.alpha = 1.0;
            }];
            CGRect rectStatus = [[UIApplication sharedApplication] statusBarFrame];
            tPosY = self.navigationController.navigationBar.frame.size.height + rectStatus.size.height;

            UIEdgeInsets inset = self.pdfListView.documentView.contentInset;
            inset.bottom = self.annotationBar.frame.size.height;
            self.pdfListView.documentView.contentInset = inset;
        }
    } else if (CPDFViewAnnotationModeSound == annotationMode && !isSelected) {
        if(CPDFSoundStateRecord == self.soundPlayBar.soundState) {
            [self.soundPlayBar stopRecord];

        } else if (CPDFSoundStatePlay== self.soundPlayBar.soundState) {
            [self.soundPlayBar stopAudioPlay];
        }
    }
}

#pragma mark - CPDFNoteOpenViewControllerDelegate

- (void)getNoteOpenViewController:(CPDFNoteOpenViewController *)noteOpenVC content:(NSString *)content isDelete:(BOOL)isDelete {
    if (isDelete) {
        [noteOpenVC.annotation.page removeAnnotation:noteOpenVC.annotation];
        [self.pdfListView setNeedsDisplayForPage:noteOpenVC.annotation.page];
        if([self.pdfListView.activeAnnotations containsObject:noteOpenVC.annotation]) {
            NSMutableArray *activeAnnotations = [NSMutableArray arrayWithArray:self.pdfListView.activeAnnotations];
            [activeAnnotations removeObject:noteOpenVC.annotation];
            [self.pdfListView updateActiveAnnotations:activeAnnotations];
        }
    } else {
        if([noteOpenVC.annotation isKindOfClass:[CPDFMarkupAnnotation class]]) {
            CPDFMarkupAnnotation *markupAnnotation = (CPDFMarkupAnnotation *)noteOpenVC.annotation;
            [markupAnnotation setContents:content?:@""];
        } else if(([noteOpenVC.annotation isKindOfClass:[CPDFTextAnnotation class]])){
            if(content && content.length > 0) {
                noteOpenVC.annotation.contents = content?:@"";
            } else {
                if([self.pdfListView.activeAnnotations containsObject:noteOpenVC.annotation]) {
                    [self.pdfListView updateActiveAnnotations:@[]];
                }
                [noteOpenVC.annotation.page removeAnnotation:noteOpenVC.annotation];
                [self.pdfListView setNeedsDisplayForPage:noteOpenVC.annotation.page];
            }
        } else {
            noteOpenVC.annotation.contents = content?:@"";
        }
    }
}

#pragma mark - CPDFSoundPlayBarDelegate

- (void)soundPlayBarRecordFinished:(CPDFSoundPlayBar *)soundPlayBar withFile:(NSString *)filePath {
    CPDFPage *page = [self.pdfListView.document pageAtIndex:[CPDFMediaManager shareManager].pageNum];
    CPDFSoundAnnotation *annotation = [[CPDFSoundAnnotation alloc] initWithDocument:self.pdfListView.document];
    
    if ([annotation setMediaPath:filePath]) {
        CGRect bounds = annotation.bounds;
        bounds.origin.x = [CPDFMediaManager shareManager].ptInPdf.x-bounds.size.width/2.0;
        bounds.origin.y = [CPDFMediaManager shareManager].ptInPdf.y-bounds.size.height/2.0;
        annotation.bounds = bounds;
        [self.pdfListView addAnnotation:annotation forPage:page];
    }

    [CPDFMediaManager shareManager].mediaState = CPDFMediaStateStop;
    [self.pdfListView stopRecord];
}

- (void)soundPlayBarRecordCancel:(CPDFSoundPlayBar *)soundPlayBar {
    if(CPDFSoundStateRecord == self.soundPlayBar.soundState) {
        [self.pdfListView stopRecord];
    }
    [CPDFMediaManager shareManager].mediaState = CPDFMediaStateStop;
}

- (void)soundPlayBarPlayClose:(CPDFSoundPlayBar *)soundPlayBar {
    [CPDFMediaManager shareManager].mediaState = CPDFMediaStateStop;
}

#pragma mark - Notification

- (void)PDFPageDidRemoveAnnotationNotification:(NSNotification *)notification {
    CPDFAnnotation *annotation = [notification object];

    if ([annotation isKindOfClass:[CPDFSoundAnnotation class]]) {
        [self.soundPlayBar stopAudioPlay];
        if ([self.soundPlayBar isDescendantOfView:self.view]) {
            [self.soundPlayBar removeFromSuperview];
        }
    }
}

#pragma mark - CPDFToolsViewControllerDelegate

- (void)CPDFToolsViewControllerDismiss:(CPDFToolsViewController *) viewController selectItemAtIndex:(CToolModel)selectIndex {
    if(CToolModelViewer == selectIndex) {
        //viewwer
        [self enterViewerMode];
    }else if(CToolModelEdit == selectIndex) {
        [self enterEditMode];
    }else if(CToolModelAnnotation == selectIndex){
        //Annotation
        [self enterAnnotationMode];
    }else if(CToolModelForm == selectIndex) {
        [self.formBar updateStatus];
        [self enterFormMode];
    }
}

#pragma mark - CPDFBOTAViewControllerDelegate

- (void)botaViewControllerDismiss:(CPDFBOTAViewController *)botaViewController {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - CPDFSignatureViewControllerDelegate

- (void)signatureViewControllerDismiss:(CPDFSignatureViewController *)signatureViewController {
    self.signatureAnnotation = nil;
}

- (void)signatureViewController:(CPDFSignatureViewController *)signatureViewController image:(UIImage *)image {
    if(self.signatureAnnotation) {
        [self.signatureAnnotation signWithImage:image];
        [self.pdfListView setNeedsDisplayForPage:self.signatureAnnotation.page];
        self.signatureAnnotation = nil;
    }
}

#pragma mark - Action

- (void)buttonItemClicked_thumbnail:(id)sender {
    if(self.pdfListView.activeAnnotations.count > 0) {
        [self.pdfListView updateActiveAnnotations:@[]];
        [self.pdfListView setNeedsDisplayForVisiblePages];
    }

    CPDFPageEditViewController *pageEditViewcontroller = [[CPDFPageEditViewController alloc] initWithPDFView:self.pdfListView];
    pageEditViewcontroller.pageEditDelegate = self;
    pageEditViewcontroller.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.navigationController presentViewController:pageEditViewcontroller animated:YES completion:nil];
}

#pragma mark - CPDFPageEditViewControllerDelegate

- (void)pageEditViewControllerDone:(CPDFPageEditViewController *)pageEditViewController {
    if (pageEditViewController.isPageEdit) {
        __weak typeof(self) weakSelf = self;
        [weakSelf reloadDocumentWithFilePath:self.filePath password:self.pdfListView.document.password completion:^(BOOL result) {
            [weakSelf.pdfListView reloadInputViews];
            [weakSelf selectDocumentRefresh];
        }];
        
        [weakSelf.pdfListView reloadInputViews];
    }
}

- (void)pageEditViewController:(CPDFPageEditViewController *)pageEditViewController pageIndex:(NSInteger)pageIndex isPageEdit:(BOOL)isPageEdit {
    if (isPageEdit) {
        __weak typeof(self) weakSelf = self;
        [weakSelf reloadDocumentWithFilePath:self.filePath password:self.pdfListView.document.password completion:^(BOOL result) {
            [weakSelf.pdfListView reloadInputViews];
            [weakSelf selectDocumentRefresh];

        }];
        
        [weakSelf.pdfListView reloadInputViews];
    }
   
    [self.pdfListView goToPageIndex:pageIndex animated:NO];
}

@end
