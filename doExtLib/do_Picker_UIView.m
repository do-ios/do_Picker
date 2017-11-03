//
//  do_Picker_View.m
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_Picker_UIView.h"

#import "doInvokeResult.h"
#import "doUIModuleHelper.h"
#import "doScriptEngineHelper.h"
#import "doIScriptEngine.h"
#import "doJsonHelper.h"
#import "doServiceContainer.h"
#import "doILogEngine.h"
#import "doTextHelper.h"

@interface do_Picker_UIView()<UIPickerViewDataSource,UIPickerViewDelegate>
{
    id<doIListData> _dataArrays;
    NSString *_currentIndex;
    NSMutableDictionary *attributeDict;

    NSMutableDictionary *selectAttributeDict;
}

@end

@implementation do_Picker_UIView
{
    UIColor *_fontColor;
    NSString *_fontStyle;
    NSInteger _fontSize;

    NSString *_selectFontColor;
    NSString *_selectFontStyle;
}
#pragma mark - doIUIModuleView协议方法（必须）
//引用Model对象
- (void) LoadView: (doUIModule *) _doUIModule
{
    _model = (typeof(_model)) _doUIModule;
    self.dataSource = self;
    self.delegate = self;
    _fontSize = [[_model GetProperty:@"fontSize"].DefaultValue intValue];
    attributeDict = [NSMutableDictionary dictionary];
    selectAttributeDict = [NSMutableDictionary dictionary];
    
    [self change_fontSize:[@(_fontSize) stringValue]];
    
    _selectFontColor = @"000000FF";
    _selectFontStyle = @"normal";
}
//销毁所有的全局对象
- (void) OnDispose
{
    self.dataSource = nil;
    self.delegate = nil;
    //自定义的全局属性,view-model(UIModel)类销毁时会递归调用<子view-model(UIModel)>的该方法，将上层的引用切断。所以如果self类有非原生扩展，需主动调用view-model(UIModel)的该方法。(App || Page)-->强引用-->view-model(UIModel)-->强引用-->view
}
//实现布局
- (void) OnRedraw
{
    //实现布局相关的修改,如果添加了非原生的view需要主动调用该view的OnRedraw，递归完成布局。view(OnRedraw)<显示布局>-->调用-->view-model(UIModel)<OnRedraw>
    //重新调整视图的x,y,w,h
    [doUIModuleHelper OnRedraw:_model];
    
    [self changeStyle];
}

#pragma mark - TYPEID_IView协议方法（必须）
#pragma mark - Changed_属性
/*
 如果在Model及父类中注册过 "属性"，可用这种方法获取
 NSString *属性名 = [(doUIModule *)_model GetPropertyValue:@"属性名"];
 
 获取属性最初的默认值
 NSString *属性名 = [(doUIModule *)_model GetProperty:@"属性名"].DefaultValue;
 */
- (void)change_index:(NSString *)newValue
{
    //自己的代码实现
    if (!newValue) {
        return;
    }
    NSInteger index = [newValue integerValue];
    _currentIndex = newValue;
    if ([_dataArrays GetCount] == 0) {
        return;
    }
    if (index > ([_dataArrays GetCount] - 1))
    {
        index = [_dataArrays GetCount] - 1;
    }
    if (index < 0)
    {
        index = 0;
    }
    _currentIndex = [@(index)stringValue];
    [self selectRow:index inComponent:0 animated:YES];
    [self fireEvent:(int)index];
    //必须延迟才有作用，因为selectRow还没有执行完毕
    [self performSelector:@selector(changeStyle) withObject:nil afterDelay:.3];
}
- (void)change_fontSize:(NSString *)newValue
{
    _fontSize = [doUIModuleHelper GetDeviceFontSize:[[doTextHelper Instance] StrToInt:newValue :[[_model GetProperty:@"fontSize"].DefaultValue intValue]] :_model.XZoom :_model.YZoom];
    [attributeDict setObject:[UIFont systemFontOfSize:_fontSize] forKey:NSFontAttributeName];
    [selectAttributeDict setObject:[UIFont systemFontOfSize:_fontSize] forKey:NSFontAttributeName];
}
- (void)change_fontColor:(NSString *)newValue
{
    _fontColor = [doUIModuleHelper GetColorFromString:newValue :[UIColor blackColor]];
    [attributeDict setObject:_fontColor forKey:NSForegroundColorAttributeName];
    
    [self reloadComponent:0];
    
    [self changeStyle];
}
- (void)change_fontStyle:(NSString *)newValue
{
    _fontStyle = newValue;
    
    if ([newValue isEqualToString:@"normal"]) {
        [attributeDict setObject:[UIFont systemFontOfSize:_fontSize] forKey:NSFontAttributeName];
    }else if ([newValue isEqualToString:@"bold"]) {
        [attributeDict setObject:[UIFont boldSystemFontOfSize:_fontSize] forKey:NSFontAttributeName];
    }else if ([newValue isEqualToString:@"italic"]) {
        CGAffineTransform matrix =  CGAffineTransformMake(1, 0, tanf(15 * (CGFloat)M_PI / 180), 1, 0, 0);
        UIFontDescriptor *desc = [ UIFontDescriptor fontDescriptorWithName :[ UIFont systemFontOfSize :_fontSize ]. fontName matrix :matrix];
        UIFont* italicFont= [ UIFont fontWithDescriptor :desc size :_fontSize];
        [attributeDict setObject:italicFont forKey:NSFontAttributeName];
    }else if ([newValue isEqualToString:@"bold_italic"]){
        //ios 不支持
    }

    [self reloadComponent:0];
    
    [self changeStyle];
}

- (void)change_selectedFontColor:(NSString *)newValue
{
    _selectFontColor = newValue;
    UIColor *color = [doUIModuleHelper GetColorFromString:_selectFontColor :[UIColor blackColor]];
    [selectAttributeDict setObject:color forKey:NSForegroundColorAttributeName];
    
    [self changeStyle];
}
- (void)change_selectedFontStyle:(NSString *)newValue
{
    _selectFontStyle = newValue;

    if ([newValue isEqualToString:@"normal"]) {
        [selectAttributeDict setObject:[UIFont systemFontOfSize:_fontSize] forKey:NSFontAttributeName];
    }else if ([newValue isEqualToString:@"bold"]) {
        [selectAttributeDict setObject:[UIFont boldSystemFontOfSize:_fontSize] forKey:NSFontAttributeName];
    }else if ([newValue isEqualToString:@"italic"]) {
        CGAffineTransform matrix =  CGAffineTransformMake(1, 0, tanf(15 * (CGFloat)M_PI / 180), 1, 0, 0);
        UIFontDescriptor *desc = [ UIFontDescriptor fontDescriptorWithName :[ UIFont systemFontOfSize :_fontSize ]. fontName matrix :matrix];
        UIFont* italicFont= [ UIFont fontWithDescriptor :desc size :_fontSize];
        [selectAttributeDict setObject:italicFont forKey:NSFontAttributeName];
    }else if ([newValue isEqualToString:@"bold_italic"]){
        //ios 不支持
    }
    [self changeStyle];
}
#pragma mark -
#pragma mark - 同步异步方法的实现
//同步
- (void)bindItems:(NSArray *)parms
{
    NSDictionary * _dictParas = [parms objectAtIndex:0];
    id<doIScriptEngine> _scriptEngine = [parms objectAtIndex:1];
    NSString* _address = [doJsonHelper GetOneText: _dictParas :@"data": nil];
    @try {
        if (_address == nil || _address.length <= 0) [NSException raise:@"doPicker" format:@"未指定相关的doPicker data参数！",nil];
        id bindingModule = [doScriptEngineHelper ParseMultitonModule: _scriptEngine : _address];
        if (bindingModule == nil) [NSException raise:@"doPicker" format:@"data参数无效！",nil];
        if([bindingModule conformsToProtocol:@protocol(doIListData)])
        {
            if(_dataArrays!= bindingModule)
                _dataArrays = bindingModule;
            if ([_dataArrays GetCount]>0) {
                [self refreshItems:parms];
            }
        }
    }
    @catch (NSException *exception) {
        [[doServiceContainer Instance].LogEngine WriteError:exception :exception.description];
        doInvokeResult* _result = [[doInvokeResult alloc]init];
        [_result SetException:exception];
        
    }
}
- (void)refreshItems:(NSArray *)parms
{
//    [self reloadAllComponents];
    [self reloadComponent:0];
    [self change_index:_currentIndex];
    
    [self changeStyle];
}


#pragma mark - 私有方法
- (void)fireEvent:(int)index;
{
    doInvokeResult *invokeResult = [[doInvokeResult alloc]init];
    [invokeResult SetResultInteger:index];
    [_model.EventCenter FireEvent:@"selectChanged" :invokeResult];
}
#pragma mark - PickerView数据源
//总共几列
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;//单列
}
//每列几行
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [_dataArrays GetCount];
}

#pragma mark - PickerView 代理方法
//每行显示的内容
- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UILabel *pickerLabel = (UILabel *)view;
    if (!pickerLabel) {
        pickerLabel = [[UILabel alloc] init];
        pickerLabel.adjustsFontSizeToFitWidth = YES;
        [pickerLabel setTextAlignment:NSTextAlignmentCenter];
    }
    id data = [_dataArrays GetData:(int)row];
    NSString *title;
    if (![data isKindOfClass:[NSString class]]) {
        if ([data respondsToSelector:@selector(stringValue)]) {
            title = [data stringValue];
        }else {
            title = [data description];
        }
    }else
        title = data;

    if (pickerLabel.attributedText.string.length>0&&row==[_currentIndex integerValue]) {
        pickerLabel.attributedText = [[NSMutableAttributedString alloc]initWithString:title attributes:selectAttributeDict];
    }else
        pickerLabel.attributedText = [[NSMutableAttributedString alloc]initWithString:title attributes:attributeDict];

    return pickerLabel;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    NSString *title = @"title";
    CGSize size = [title sizeWithAttributes:attributeDict];
    return size.height + 10;
}
//点击某行触发
-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    [self fireEvent:(int)row];
    //修改内存中得index值
    _currentIndex = [NSString stringWithFormat:@"%d",(int)row];
    [_model SetPropertyValue:@"index" :[NSString stringWithFormat:@"%ld",(long)row]];
    [self changeStyle];
}
- (void)changeStyle
{
    NSInteger row = [_currentIndex integerValue];
    NSInteger count = [self numberOfRowsInComponent:0];
    if (count<0||(row<0||row>=count)) {
        return;
    }
    UIView *v = [self viewForRow:row forComponent:0];
    UILabel *pickerLabel = (UILabel *)v;
    if (pickerLabel.attributedText.string.length>0) {
        pickerLabel.attributedText = [[NSMutableAttributedString alloc]initWithString:pickerLabel.attributedText.string attributes:selectAttributeDict];
    }
}
#pragma mark - doIUIModuleView协议方法（必须）<大部分情况不需修改>
- (BOOL) OnPropertiesChanging: (NSMutableDictionary *) _changedValues
{
    //属性改变时,返回NO，将不会执行Changed方法
    return YES;
}
- (void) OnPropertiesChanged: (NSMutableDictionary*) _changedValues
{
    //_model的属性进行修改，同时调用self的对应的属性方法，修改视图
    [doUIModuleHelper HandleViewProperChanged: self :_model : _changedValues ];
}
- (BOOL) InvokeSyncMethod: (NSString *) _methodName : (NSDictionary *)_dicParas :(id<doIScriptEngine>)_scriptEngine : (doInvokeResult *) _invokeResult
{
    //同步消息
    return [doScriptEngineHelper InvokeSyncSelector:self : _methodName :_dicParas :_scriptEngine :_invokeResult];
}
- (BOOL) InvokeAsyncMethod: (NSString *) _methodName : (NSDictionary *) _dicParas :(id<doIScriptEngine>) _scriptEngine : (NSString *) _callbackFuncName
{
    //异步消息
    return [doScriptEngineHelper InvokeASyncSelector:self : _methodName :_dicParas :_scriptEngine: _callbackFuncName];
}
- (doUIModule *) GetModel
{
    //获取model对象
    return _model;
}

@end
