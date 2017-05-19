//
//  ViewController.h
//  FogFrame
//
//  Created by Anirban on 5/9/17.
//  Copyright © 2017 Anirban. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "TestViewController.h"
@interface ViewController : UIViewController<AVCaptureMetadataOutputObjectsDelegate>
    
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (weak, nonatomic) IBOutlet UIView *viewPreview;
@property (weak, nonatomic) IBOutlet UITextField *NameTextField;
@property TestViewController *v;
@end

