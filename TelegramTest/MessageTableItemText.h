//
//  MessageTableItemText.h
//  Telegram P-Edition
//
//  Created by Dmitry Kondratyev on 1/26/14.
//  Copyright (c) 2014 keepcoder. All rights reserved.
//

#import "MessageTableItem.h"
#import "TGCTextMark.h"
@interface MessageTableItemText : MessageTableItem

@property (nonatomic, strong) NSMutableAttributedString *textAttributed;
@property (nonatomic,strong) NSDictionary *textAttributes;

@property (nonatomic,strong) SearchSelectItem *mark;

@property (nonatomic,assign) NSSize textSize;


@property (nonatomic,strong,readonly) NSAttributedString *webPageTitle;
@property (nonatomic,strong,readonly) TGImageObject *webPageImageObject;
@property (nonatomic,strong,readonly) NSAttributedString *webPageDesc;
@property (nonatomic,strong,readonly) NSString *webPageToolTip;


-(void)updateMessageFont;

-(void)updateWebPage;


-(BOOL)isWebPage;

-(NSSize)webBlockSize;

@end
