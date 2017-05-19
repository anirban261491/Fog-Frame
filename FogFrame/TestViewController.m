//
//  TestViewController.m
//  FogFrame
//
//  Created by Anirban on 5/18/17.
//  Copyright © 2017 Anirban. All rights reserved.
//

#import "TestViewController.h"
#import "AppDelegate.h"
#import "FrameCollectionViewCell.h"
#import "DBManager.h"
#import "ViewController.h"
@import CocoaAsyncSocket;
@interface TestViewController ()<GCDAsyncSocketDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate,UICollectionViewDelegate,UICollectionViewDataSource,UIScrollViewDelegate>
{
    UIImageView *DraggedImageView;
    UILongPressGestureRecognizer *lpgr;
    float oldX, oldY;
    GCDAsyncSocket *socket;
    UIView *highlightView;
    NSString *SSID,*IP,*Port;
}
@property (nonatomic, strong) DBManager *dbManager;
@end
BOOL isImageUpdated;
int UserID=1;
@implementation TestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.dbManager = [[DBManager alloc] initWithDatabaseFilename:@"Database.db"];
    _FrameArray=[NSMutableArray new];
    //[FrameArray addObject:[[NSMutableDictionary alloc] initWithDictionary: @{@"Name":@"Frame 1",@"SSID":@"Rasika's PC",@"IP":@"192.168.42.1",@"Port":@"9444",@"Image":[UIImage imageNamed:@"selectImageIcon.png"]}]];
    //[FrameArray addObject:[[NSMutableDictionary alloc] initWithDictionary:@{@"Name":@"Frame 2",@"SSID":@"RasPi_AP2",@"IP":@"192.168.42.2",@"Port":@"9444",@"Image":[UIImage imageNamed:@"selectImageIcon.png"]}] ];
    //_FramePageControl.numberOfPages=_FrameArray.count;
    _FrameView.layer.borderWidth=1.0f;
    _FrameView.layer.borderColor=[[UIColor colorWithRed:8.0/255.0 green:150.0/255.0 blue:196.0/255.0 alpha:1] CGColor];
    [AppDelegate setConnectionViewController:self];
    
    UITapGestureRecognizer *tap=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectImage)];
    [_imageView addGestureRecognizer:tap];
    lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGestures:)];
    lpgr.minimumPressDuration = 0.5f;
    lpgr.allowableMovement = 100.0f;
    
    [self.imageView addGestureRecognizer:lpgr];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                            action:@selector(activateDeletionMode:)];
    longPress.delegate = self;
    [_FrameCollectionView addGestureRecognizer:longPress];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:YES];
    [_FrameCollectionView reloadData];
    _FramePageControl.numberOfPages=_FrameArray.count;
}

-(void)loadData{
    // Form the query.
    NSString *query = [NSString stringWithFormat:@"select * from Frames where UserID=%d",UserID];

    if (_FrameArray != nil) {
        _FrameArray = nil;
    }
    _FrameArray = [[NSMutableArray alloc] initWithArray:[self.dbManager loadDataFromDB:query]];
    
    [self.FrameCollectionView reloadData];
}
-(void)selectImage
{
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:nil
                                 message:nil
                                 preferredStyle:UIAlertControllerStyleActionSheet];
    
    
    
    UIAlertAction* cameraButton = [UIAlertAction
                               actionWithTitle:@"Camera"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   [self cameraSelected];
                               }];
    
    UIAlertAction* libraryButton = [UIAlertAction
                                   actionWithTitle:@"Photo Library"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {
                                       [self photoLibrarySelected];
                                   }];
    
    UIAlertAction* cancelButton = [UIAlertAction
                                    actionWithTitle:@"Cancel"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action) {
                                       
                                    }];
    [alert addAction:cameraButton];
    [alert addAction:libraryButton];
    [alert addAction:cancelButton];
    [self presentViewController:alert animated:YES completion:nil];
    
}

-(void)photoLibrarySelected
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [self presentViewController:picker animated:YES completion:NULL];
}

-(void)cameraSelected
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    [self presentViewController:picker animated:YES completion:NULL];
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    self.imageView.image = chosenImage;
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}

- (void)handleLongPressGestures:(UILongPressGestureRecognizer *)sender
{
    if ([sender isEqual:lpgr]) {
        CGPoint touchLocation = [sender locationInView:self.view];
        if (sender.state == UIGestureRecognizerStateBegan)
        {
            DraggedImageView=[UIImageView new];
            DraggedImageView.frame=CGRectMake(0, 0, _imageView.frame.size.width-20, _imageView.frame.size.height-20);
            DraggedImageView.center=_imageView.center;
            DraggedImageView.contentMode=UIViewContentModeScaleAspectFit;
            DraggedImageView.alpha=0.5f;
            DraggedImageView.userInteractionEnabled=YES;
            DraggedImageView.image=self.imageView.image;
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
            if(CGRectIntersectsRect(DraggedImageView.frame, _FrameCollectionView.frame))
            {
                if(!highlightView)
                {
                    highlightView = [[UIView alloc]initWithFrame:_FrameCollectionView.bounds];
                    highlightView.backgroundColor = [UIColor blueColor];
                    highlightView.alpha=0.5f;
                    [_FrameCollectionView addSubview: highlightView];
                }
            }
            else if(highlightView)
            {
                [highlightView removeFromSuperview];
                highlightView=nil;
            }
        }
        else if (sender.state == UIGestureRecognizerStateEnded)
        {
            if(highlightView&&_FrameArray.count>0)
            {
                [highlightView removeFromSuperview];
                highlightView=nil;
                SSID=[_FrameArray[self.FramePageControl.currentPage] valueForKey:@"SSID"];
                IP=[_FrameArray[self.FramePageControl.currentPage] valueForKey:@"IP"];
                Port=[_FrameArray[self.FramePageControl.currentPage] valueForKey:@"Port"];
                [self sendImage];
            }
            else if(_FrameArray.count==0)
            {
                [highlightView removeFromSuperview];
                highlightView=nil;
                UIAlertController * alert = [UIAlertController
                                             alertControllerWithTitle:nil
                                             message:@"Please add a frame to transfer images"
                                             preferredStyle:UIAlertControllerStyleAlert];
                
                
                
                UIAlertAction* okButton = [UIAlertAction
                                           actionWithTitle:@"Ok"
                                           style:UIAlertActionStyleDefault
                                           handler:^(UIAlertAction * action) {
                                               
                                           }];
                [alert addAction:okButton];
                
                [self presentViewController:alert animated:YES completion:nil];
            }
            [DraggedImageView removeFromSuperview];
            
        }
    }
}


-(void)sendImage{
    socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    NSError *err = nil;
    if (![socket connectToHost:IP onPort:[Port intValue] withTimeout:1 error:&err])
    {
        NSLog(@"I goofed: %@", err);
    }
}
- (void)socket:(GCDAsyncSocket *)sender didConnectToHost:(NSString *)host port:(UInt16)port
{
    [socket writeData:UIImagePNGRepresentation(self.imageView.image) withTimeout:-1 tag:1];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    if(err.code==GCDAsyncSocketConnectTimeoutError)
    {
        NSString *alertMessage=[NSString stringWithFormat:@"You are not connected to this frame. Please connect to '%@' SSID to transfer image.",SSID];
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:nil
                                     message:alertMessage
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        
        
        UIAlertAction* yesButton = [UIAlertAction
                                    actionWithTitle:@"Ok"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action) {
                                           [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"App-Prefs:root=WIFI"] options:@{} completionHandler:^(BOOL success) {
                                               isImageUpdated=true;
                                            }];
                                    }];
        UIAlertAction* cancelButton = [UIAlertAction
                                       actionWithTitle:@"Cancel"
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction * action) {
                                           
                                       }];
        [alert addAction:cancelButton];
        [alert addAction:yesButton];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    [socket disconnect];
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:nil
                                 message:@"Transfer successful"
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    
    
    UIAlertAction* okButton = [UIAlertAction
                                actionWithTitle:@"Ok"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
                                    NSMutableDictionary *d=_FrameArray[_FramePageControl.currentPage];
                                    [d setObject:self.imageView.image forKey:@"Image"];
                                    [_FrameArray setObject:d atIndexedSubscript:_FramePageControl.currentPage];
                                    NSIndexPath *indexPath=[NSIndexPath indexPathForRow:_FramePageControl.currentPage inSection:0];
                                    [_FrameCollectionView reloadItemsAtIndexPaths:@[indexPath]];
                                    isImageUpdated=false;
                                }];
        [alert addAction:okButton];
   
    [self presentViewController:alert animated:YES completion:nil];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _FrameArray.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"FrameCollectionViewCell";
    FrameCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    cell.layer.borderWidth=1.0f;
    cell.layer.borderColor=[[UIColor colorWithRed:8.0/255.0 green:150.0/255.0 blue:196.0/255.0 alpha:1] CGColor];
    cell.FrameNameLabel.text=[_FrameArray[indexPath.row] objectForKey:@"Name"];
    cell.ImageView.image=[_FrameArray[indexPath.row] objectForKey:@"Image"];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(CGRectGetWidth(collectionView.frame), (CGRectGetHeight(collectionView.frame)));
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    CGFloat pageWidth = self.FramePageControl.frame.size.width;
    self.FramePageControl.currentPage = self.FrameCollectionView.contentOffset.x / pageWidth;
}


- (void)activateDeletionMode:(UILongPressGestureRecognizer *)gr
{
    if (gr.state == UIGestureRecognizerStateBegan) {
            NSIndexPath *indexPath = [_FrameCollectionView indexPathForItemAtPoint:[gr locationInView:_FrameCollectionView]];
        NSString *alertMessage=[NSString stringWithFormat:@"Confirm deletion of frame named %@",[_FrameArray[indexPath.row] valueForKey:@"Name"]];
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:nil
                                     message:alertMessage
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        
        
        UIAlertAction* yesButton = [UIAlertAction
                                    actionWithTitle:@"Yes"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action) {
                                        [_FrameArray removeObjectAtIndex:indexPath.row];
                                        [_FrameCollectionView reloadData];
                                        _FramePageControl.numberOfPages=_FrameArray.count;
                                    }];
        UIAlertAction* cancelButton = [UIAlertAction
                                       actionWithTitle:@"Cancel"
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction * action) {
                                           
                                       }];
        [alert addAction:cancelButton];
        [alert addAction:yesButton];
        [self presentViewController:alert animated:YES completion:nil];

    }
}
- (IBAction)addFramePressed:(id)sender {
    ViewController *v=[self.storyboard instantiateViewControllerWithIdentifier:@"ViewController"];
    v.v=self;
    [self.navigationController pushViewController:v animated:YES];
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
