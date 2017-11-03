//
//  do_Picker_View.h
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "do_Picker_IView.h"
#import "do_Picker_UIModel.h"
#import "doIUIModuleView.h"

@interface do_Picker_UIView : UIPickerView<do_Picker_IView, doIUIModuleView>
//可根据具体实现替换UIView
{
	@private
		__weak do_Picker_UIModel *_model;
}

@end
