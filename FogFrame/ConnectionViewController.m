//
//  ConnectionViewController.m
//  FogFrame
//
//  Created by Anirban on 5/10/17.
//  Copyright © 2017 Anirban. All rights reserved.
//

#import "ConnectionViewController.h"

@interface ConnectionViewController ()<NSStreamDelegate>
{
    NSInputStream *inputStream;
    NSOutputStream *outputStream;
}
@end

@implementation ConnectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}
- (IBAction)initiateNetworkCommunication:(id)sender {
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)@"192.168.42.1", 9444, &readStream, &writeStream);
    inputStream = (__bridge NSInputStream *)readStream;
    outputStream = (__bridge NSOutputStream *)writeStream;
    [inputStream setDelegate:self];
    [outputStream setDelegate:self];
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [inputStream open];
    [outputStream open];
}

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    NSLog(@"stream event %lu", (unsigned long)streamEvent);
}

- (IBAction)sendMessage:(id)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [self presentViewController:picker animated:YES completion:NULL];
   
//    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"App-Prefs:root=WIFI"] options:@{} completionHandler:^(BOOL success) {
//        NSLog(@"Hello");
//    }];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    self.imageView.image = chosenImage;
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}
- (IBAction)sendImage:(id)sender {
    NSData *imgData = UIImagePNGRepresentation(self.imageView.image);
    
    NSMutableData *completeData = [NSMutableData new];
    [completeData appendData:imgData];
    
    NSInteger bytesWritten = 0;
    while ( completeData.length > bytesWritten )
    {
        while ( !outputStream.hasSpaceAvailable )
            [NSThread sleepForTimeInterval:0.05];
        
        //sending NSData over to server
        NSInteger writeResult = [outputStream write:[completeData bytes]+bytesWritten maxLength:[completeData length]-bytesWritten];
        if ( writeResult == -1 ) {
            NSLog(@"error code here");
        }
        else {
            bytesWritten += writeResult;
        }
    }}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
