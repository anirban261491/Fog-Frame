//
//  ConnectionViewController.m
//  FogFrame
//
//  Created by Anirban on 5/10/17.
//  Copyright © 2017 Anirban. All rights reserved.
//

#import "ConnectionViewController.h"

@interface ConnectionViewController ()<NSStreamDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>
{
    NSInputStream *inputStream;
    NSOutputStream *outputStream;
    BOOL flag_canSendDirectly;
    NSInteger currentDataOffset;
    uint8_t *readBytes;
    NSUInteger dataLength;
    NSData *imgData;
    float oldX, oldY;
    UIImageView *DraggedImageView;
    UILongPressGestureRecognizer *lpgr;
}
@property NSMutableArray* dataWriteQueue;

@end

@implementation ConnectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _FrameImageView.layer.borderColor=[[UIColor grayColor] CGColor];
    _FrameImageView.layer.borderWidth=1.0f;
    _dataWriteQueue=[NSMutableArray new];
    currentDataOffset=0;
    UITapGestureRecognizer *tap=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectImage)];
    [_imageView addGestureRecognizer:tap];
    lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGestures:)];
    lpgr.minimumPressDuration = 0.5f;
    lpgr.allowableMovement = 100.0f;
    
    [self.imageView addGestureRecognizer:lpgr];
    
}

-(void)selectImage
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [self presentViewController:picker animated:YES completion:NULL];
}


- (void)handleLongPressGestures:(UILongPressGestureRecognizer *)sender
{
    if ([sender isEqual:lpgr]) {
        CGPoint touchLocation = [sender locationInView:self.view];
        if (sender.state == UIGestureRecognizerStateBegan)
        {
            DraggedImageView=[[UIImageView alloc] initWithImage:_imageView.image];
            DraggedImageView.frame=CGRectMake(0, 0, _imageView.frame.size.width-20, _imageView.frame.size.height-20);
            DraggedImageView.center=_imageView.center;
            DraggedImageView.contentMode=UIViewContentModeScaleAspectFit;
            DraggedImageView.alpha=0.5f;
            DraggedImageView.userInteractionEnabled=YES;
            [self.view addSubview:DraggedImageView];
            oldX = touchLocation.x;
            oldY = touchLocation.y;
        }
        else if (sender.state == UIGestureRecognizerStateChanged)
        {
            CGRect frame = DraggedImageView.frame;
            frame.origin.x = DraggedImageView.frame.origin.x + touchLocation.x - oldX;
            frame.origin.y =  DraggedImageView.frame.origin.y + touchLocation.y - oldY;
            DraggedImageView.frame = frame;
            oldX = touchLocation.x;
            oldY = touchLocation.y;
        }
        else if (sender.state == UIGestureRecognizerStateEnded)
        {
            [DraggedImageView removeFromSuperview];
            [self sendImage];
        }
    }
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
        
        case NSStreamEventErrorOccurred:{
            break;
        }
        
        case NSStreamEventOpenCompleted:{
            
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
- (void)sendImage {
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)@"192.168.42.2", 9444, &readStream, &writeStream);
    inputStream = (__bridge NSInputStream *)readStream;
    outputStream = (__bridge NSOutputStream *)writeStream;
    [inputStream setDelegate:self];
    [outputStream setDelegate:self];
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [inputStream open];
    [outputStream open];
    imgData = UIImagePNGRepresentation(self.imageView.image);
    dataLength = [imgData length];
    readBytes = (uint8_t *)[imgData bytes];
    [self _sendData];
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
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:nil
                                         message:@"Transfer successful"
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            
            
            UIAlertAction* yesButton = [UIAlertAction
                                        actionWithTitle:@"Ok"
                                        style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * action) {
                                            _FrameImageView.image=self.imageView.image;
                                        }];
            [alert addAction:yesButton];
            [self presentViewController:alert animated:YES completion:nil];
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
