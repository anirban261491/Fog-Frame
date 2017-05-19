//
//  TestViewController.h
//  FogFrame
//
//  Created by Anirban on 5/18/17.
//  Copyright © 2017 Anirban. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TestViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UICollectionView *FrameCollectionView;
@property (weak, nonatomic) IBOutlet UIView *FrameView;
@property (weak, nonatomic) IBOutlet UIPageControl *FramePageControl;
-(void)sendImage;
@property NSMutableArray *FrameArray;
@end
