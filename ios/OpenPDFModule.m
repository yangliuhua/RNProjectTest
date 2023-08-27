//
//  ViewController.h
//   PDFView_RN
//
//  Copyright © 2014-2023 PDF Technologies, Inc. All Rights Reserved.
//
//  THIS SOURCE CODE AND ANY ACCOMPANYING DOCUMENTATION ARE PROTECTED BY INTERNATIONAL COPYRIGHT LAW
//  AND MAY NOT BE RESOLD OR REDISTRIBUTED. USAGE IS BOUND TO THE ComPDFKit LICENSE AGREEMENT.
//  UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS SUBJECT TO CIVIL AND CRIMINAL PENALTIES.
//  This notice may not be removed from this file.
//

#import "OpenPDFModule.h"
#import "CPDFViewController.h"
#import "AppDelegate.h"

#import <ComPDFKit/ComPDFKit.h>

@implementation OpenPDFModule

RCT_EXPORT_MODULE();


RCT_EXPORT_METHOD(openPDF) {
  dispatch_async(dispatch_get_main_queue(), ^{
    AppDelegate *delegate = (AppDelegate *)([UIApplication sharedApplication].delegate);
    NSString *documentPath = [[NSBundle mainBundle] pathForResource:@"developer_guide_ios" ofType:@"pdf"];
    UIViewController *rootNav = delegate.rootViewController;
    CPDFViewController *pdfViewController = [[CPDFViewController alloc] initWithFilePath:documentPath password:nil];
    UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:pdfViewController];
    [rootNav presentViewController:nav animated:YES completion:nil];
  });
}

RCT_EXPORT_METHOD(openPDFByPath:(nonnull NSString *)filePath) {
  dispatch_async(dispatch_get_main_queue(), ^{
    AppDelegate *delegate = (AppDelegate *)([UIApplication sharedApplication].delegate);
    UIViewController *rootNav = delegate.rootViewController;
    CPDFViewController *pdfViewController = [[CPDFViewController alloc] initWithFilePath:filePath password:nil];
    UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:pdfViewController];

    [rootNav presentViewController:nav animated:YES completion:nil];
  });
  
}

RCT_EXPORT_METHOD(setLicenseKey:(nonnull NSString *)key secret:(nonnull NSString *)secret) {
  [CPDFKit setLicenseKey:key secret:secret];
}

@end
