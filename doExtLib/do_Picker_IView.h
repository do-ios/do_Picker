//
//  do_Picker_UI.h
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol do_Picker_IView <NSObject>

@required
//属性方法
- (void)change_index:(NSString *)newValue;
- (void)change_fontColor:(NSString *)newValue;
- (void)change_fontStyle:(NSString *)newValue;
- (void)change_selectedFontColor:(NSString *)newValue;
- (void)change_selectedFontStyle:(NSString *)newValue;

//同步或异步方法
- (void)bindItems:(NSArray *)parms;
- (void)refreshItems:(NSArray *)parms;


@end