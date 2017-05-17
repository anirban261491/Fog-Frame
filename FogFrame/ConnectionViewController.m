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
    BOOL flag_canSendDirectly;
    NSInteger currentDataOffset;
    uint8_t *readBytes;
    NSUInteger dataLength;
    NSData *imgData;
}
@property NSMutableArray* dataWriteQueue;

@end

@implementation ConnectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _dataWriteQueue=[NSMutableArray new];
    currentDataOffset=0;
}
- (IBAction)initiateNetworkCommunication:(id)sender {
    
}

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    switch(streamEvent)
    {
        case NSStreamEventHasSpaceAvailable: {
            [self _sendData];
            break;
    }
        case NSStreamEventEndEncountered: {
                break;
        }

    }
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
    imgData = UIImageJPEGRepresentation (self.imageView.image,1.0);
    dataLength = [imgData length];
    readBytes = (uint8_t *)[imgData bytes];
    [self _sendData];
//    NSMutableData *completeData = [NSMutableData new];
//    [completeData appendData:imgData];
//    
//    NSInteger bytesWritten = 0;
//    while ( completeData.length > bytesWritten )
//    {
//        while ( !outputStream.hasSpaceAvailable )
//            [NSThread sleepForTimeInterval:0.05];
//        
//        //sending NSData over to server
//        NSInteger writeResult = [outputStream write:[completeData bytes]+bytesWritten maxLength:[completeData length]-bytesWritten];
//        if ( writeResult == -1 ) {
//            NSLog(@"error code here");
//        }
//        else {
//            bytesWritten += writeResult;
//        }
//    }
}

- (void)sendData:(NSData *)data {
    
}

- (void)_sendData {
    if (readBytes==NULL) {
        return;
    }
    readBytes = (uint8_t *)[imgData bytes];
    readBytes += currentDataOffset;
    
    NSUInteger lengthOfDataToWrite = (dataLength - currentDataOffset >= 1024) ? 1024 : (dataLength - currentDataOffset);
    NSInteger bytesWritten = [outputStream write:readBytes maxLength:lengthOfDataToWrite];
    if (bytesWritten > 0) {
        currentDataOffset += bytesWritten;
        if (currentDataOffset == dataLength) {
            currentDataOffset = 0;
            readBytes=NULL;
            [outputStream close];
            [inputStream close];
        }
    }
}

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
