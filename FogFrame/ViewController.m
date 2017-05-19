//
//  ViewController.m
//  FogFrame
//
//  Created by Anirban on 5/9/17.
//  Copyright © 2017 Anirban. All rights reserved.
//

#import "ViewController.h"
#import "DBManager.h"
@interface ViewController ()
@property (nonatomic, strong) DBManager *dbManager;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.dbManager = [[DBManager alloc] initWithDatabaseFilename:@"Database.db"];
}

- (IBAction)startRecording:(id)sender {
    NSError *error;
    
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    
    if (!input) {
        NSLog(@"%@", [error localizedDescription]);
    }
    _captureSession = [[AVCaptureSession alloc] init];
    [_captureSession addInput:input];
    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    [_captureSession addOutput:captureMetadataOutput];
    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create("myQueue", NULL);
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
    [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
    
    _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    [_videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [_videoPreviewLayer setFrame:_viewPreview.layer.bounds];
    [_viewPreview.layer addSublayer:_videoPreviewLayer];
    [_captureSession startRunning];
}

    
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            [_captureSession stopRunning];
            NSData *data = [[metadataObj stringValue] dataUsingEncoding:NSUTF8StringEncoding];
            NSError *err = nil;
            NSMutableDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&err];
            NSString *alertMessage=[NSString stringWithFormat:@"Do you want to add this frame?"];
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:nil
                                         message:alertMessage
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            
            
            UIAlertAction* yesButton = [UIAlertAction
                                        actionWithTitle:@"Yes"
                                        style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * action) {
                                            if([self.NameTextField.text isEqualToString:@""])
                                            {
                                                UIAlertController * alert = [UIAlertController
                                                                             alertControllerWithTitle:nil
                                                                             message:@"Please enter a name for this frame"
                                                                             preferredStyle:UIAlertControllerStyleAlert];
                                                
                                                
                                                
                                                UIAlertAction* yesButton = [UIAlertAction
                                                                            actionWithTitle:@"Ok"
                                                                            style:UIAlertActionStyleDefault
                                                                            handler:^(UIAlertAction * action) {}];
                                                [alert addAction:yesButton];
                                                [self presentViewController:alert animated:YES completion:nil];
                                            }
                                            else
                                            {
                                                //[self saveFrameToDB:json];
                                                [_v.FrameArray addObject:[[NSMutableDictionary alloc] initWithDictionary: @{@"Name":self.NameTextField.text,@"SSID":[json valueForKey:@"SSID"],@"IP":[json valueForKey:@"IP"],@"Port":[json valueForKey:@"Port"] ,@"Image":[UIImage imageNamed:@"selectImageIcon.png"]}]];
                                                UIAlertController * alert = [UIAlertController
                                                                             alertControllerWithTitle:nil
                                                                             message:@"Frame added successfully"
                                                                             preferredStyle:UIAlertControllerStyleAlert];
                                                
                                                
                                                
                                                UIAlertAction* okButton = [UIAlertAction
                                                                           actionWithTitle:@"Ok"
                                                                           style:UIAlertActionStyleDefault
                                                                           handler:^(UIAlertAction * action) {
                                                                               [self.navigationController popViewControllerAnimated:YES];
                                                                           }];
                                                [alert addAction:okButton];
                                                
                                                [self presentViewController:alert animated:YES completion:nil];
                                            }
                                        }];
            UIAlertAction* cancelButton = [UIAlertAction
                                           actionWithTitle:@"No"
                                           style:UIAlertActionStyleDefault
                                           handler:^(UIAlertAction * action) {
                                               
                                           }];
            [alert addAction:cancelButton];
            [alert addAction:yesButton];
            [self presentViewController:alert animated:YES completion:nil];
            
        }
    }
}

-(void)saveFrameToDB:(NSDictionary*)d
{
    NSString *query = [NSString stringWithFormat:@"insert into Frames values('%@','%@', '%@', %d,%d)", self.NameTextField.text, [d valueForKey:@"SSID"], [d valueForKey:@"IP"],1,[[d valueForKey:@"Port"] intValue]];
    [self.dbManager executeQuery:query];
    if (self.dbManager.affectedRows != 0) {
        NSLog(@"Query was executed successfully. Affected rows = %d", self.dbManager.affectedRows);
    }
    else{
        NSLog(@"Could not execute the query.");
    }
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return YES;
}
- (IBAction)backPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
