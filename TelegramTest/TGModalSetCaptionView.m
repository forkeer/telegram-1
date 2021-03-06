//
//  TGModalSetCaptionView.m
//  Telegram
//
//  Created by keepcoder on 23.04.15.
//  Copyright (c) 2015 keepcoder. All rights reserved.
//

#import "TGModalSetCaptionView.h"
#import "TGImageAttachment.h"
#import "TGModernESGViewController.h"
#import "NSTextView+EmojiExtension.h"
#import "TGPopoverHint.h"

@interface TGModalSetCaptionView ()
-(void)changeResponder;
@property (nonatomic,assign) NSUInteger currentResponderId;
@end

@interface TGAttachCaptionRowItem : TMRowItem<TMGrowingTextViewDelegate>
@property (nonatomic,strong) TGImageAttachment *attach;
@property (nonatomic,strong) TGModalSetCaptionView *controller;
@property (nonatomic,strong) TMGrowingTextView *textView;
@end

@interface TGAttachCaptionRowView : TMRowView<NSTextViewDelegate>
@property (nonatomic,strong) TMGrowingTextView *textView;
@property (nonatomic,strong) BTRButton *emojiButton;
@property (nonatomic, strong) RBLPopover *popover;
@end



@implementation TGAttachCaptionRowItem


-(id)initWithObject:(id)object {
    if(self = [super initWithObject:object]) {
        _attach = object;
    }
    
    return self;
}

-(NSUInteger)hash {
    return _attach.item.unique_id;
}


- (void) TMGrowingTextViewNeedClose:(id)textView {
    [_controller mouseUp:nil];
}


- (void) TMGrowingTextViewHeightChanged:(id)textView height:(int)height cleared:(BOOL)isCleared {
    
}
- (BOOL) TMGrowingTextViewCommandOrControlPressed:(TMGrowingTextView *)textView isCommandPressed:(BOOL)isCommandPressed {
    
    BOOL isNeedSend = ([SettingsArchiver checkMaskedSetting:SendEnter] && !isCommandPressed) || ([SettingsArchiver checkMaskedSetting:SendCmdEnter] && isCommandPressed);
    
    if(isNeedSend) {
        if([TGPopoverHint isShown]) {
            [[TGPopoverHint hintView] performSelected];
        } else
            [_controller changeResponder];
    } else
    {
        [_textView insertNewline:nil];
    }
    
    return YES;
}
- (void) TMGrowingTextViewTextDidChange:(TMGrowingTextView *)textView {
    
    
    
    [_attach.item changeCaption:_textView.string needSave:NO];
    
}
- (void) TMGrowingTextViewFirstResponder:(id)textView isFirstResponder:(BOOL)isFirstResponder {
    if(isFirstResponder) {
        _controller.currentResponderId = [self.table positionOfItem:self];
    }
}

@end


@implementation TGAttachCaptionRowView


-(instancetype)initWithFrame:(NSRect)frameRect {
    if(self = [super initWithFrame:frameRect]) {
        
        
        
        _textView = [[TMGrowingTextView alloc] initWithFrame:NSMakeRect(80, 4, NSWidth(frameRect) - 84, NSHeight(frameRect) - 12)];
        
        _textView.delegate = self;
        
        
        _textView.containerView.frame = NSMakeRect(75, 4, NSWidth(frameRect) - 79, NSHeight(frameRect) - 9);
        
        _textView.minHeight = _textView.maxHeight = NSHeight(_textView.containerView.frame);
        _textView.limit = 140;
        [_textView setFont:TGSystemFont(13)];
        
        
        _emojiButton = [[BTRButton alloc] initWithFrame:NSMakeRect(_textView.containerView.frame.size.width - image_smile().size.width - 7, NSHeight(_textView.frame) - image_smile().size.height - 5, image_smile().size.width, image_smile().size.height)];
        [_emojiButton setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin];
        [_emojiButton.layer disableActions];
        
        
        NSImage *smile_h = [image_smile() imageTintedWithColor:BLUE_ICON_COLOR];

        
        [_emojiButton setBackgroundImage:image_smile() forControlState:BTRControlStateNormal];
        [_emojiButton setBackgroundImage:smile_h forControlState:BTRControlStateHover];
        [_emojiButton setBackgroundImage:smile_h forControlState:BTRControlStateHighlighted];
        [_emojiButton setBackgroundImage:smile_h forControlState:BTRControlStateSelected | BTRControlStateHover];
        [_emojiButton setBackgroundImage:smile_h forControlState:BTRControlStateSelected];
        
        
        [_emojiButton addTarget:self action:@selector(smileButtonEntered:) forControlEvents:BTRControlEventMouseEntered];
        [_emojiButton addTarget:self action:@selector(smileButtonClick:) forControlEvents:BTRControlEventClick];
        [_textView.containerView addSubview:_emojiButton];
     
        
        [_textView setFrameSize:NSMakeSize(NSWidth(_textView.containerView.frame) - 40, NSHeight(_textView.containerView.frame))];
        
    }
    
    
    return self;
}


- (void)textDidChange:(NSNotification *)notification {
    [_textView textDidChange:notification];
    
    [_textView tryShowHintView:[Telegram conversation]];
}

- (void)smileButtonEntered:(BTRButton *)button {
    
    [self smileButtonClick:button];
}

- (void)smileButtonClick:(BTRButton *)button {
    
    
    TGModernESGViewController *egsViewController = [TGModernESGViewController controller];
    
    [egsViewController setMessagesViewController:nil];
    
    weak();
    if(!_popover) {
        
        _popover = [[RBLPopover alloc] initWithContentViewController:(NSViewController *)egsViewController];
        [_popover setHoverView:self.emojiButton];
        _popover.animates = NO;
        [_popover setDidCloseBlock:^(RBLPopover *popover){
            [weakSelf.emojiButton setSelected:NO];
            [egsViewController close];
        }];
        
    }
    
    egsViewController.epopover = _popover;
    
    [egsViewController.emojiViewController setInsertEmoji:^(NSString *emoji) {
        [weakSelf.textView insertText:emoji];
    }];
    
    [_emojiButton setSelected:YES];
    
    NSRect frame = _emojiButton.bounds;
    frame.origin.y += 4;
    
    if(!_popover.isShown) {
        [_popover showRelativeToRect:frame ofView:_emojiButton preferredEdge:CGRectMaxYEdge];
        [egsViewController show];
    }
    
    
}


-(void)redrawRow {
    
    TGAttachCaptionRowItem *item = (TGAttachCaptionRowItem *) [self rowItem];
    
    _textView.growingDelegate = item;
    
    item.textView = _textView;
    
    [self removeAllSubviews];
    
    [_textView setString:item.attach.item.caption];
    
    [self addSubview:_textView.containerView];
    
    [item.attach setFrameOrigin:NSMakePoint(4, 4)];
    
    [item.attach setDeleteAccept:NO];
    
    [self addSubview:item.attach];
    
}


-(BOOL)becomeFirstResponder {
    
    
    [[[Telegram delegate] mainWindow] makeFirstResponder:_textView];
    
    return YES;
}

@end

@interface TGModalSetCaptionView ()<TMTableViewDelegate>
@property (nonatomic,strong) TMView *containerView;
@property (nonatomic,strong) TMView *backgroundView;

@property (nonatomic,strong) BTRImageView *imageView;
@property (nonatomic,strong) TMTextView *textView;

@property (nonatomic,strong) TMView *textViewBorder;

@property (nonatomic,strong) TL_conversation *conversation;

@property (nonatomic,strong) TMTableView *tableView;



@end

@implementation TGModalSetCaptionView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}


-(instancetype)initWithFrame:(NSRect)frameRect {
    if(self = [super initWithFrame:frameRect]) {
        
        self.backgroundColor = [NSColor clearColor];
        
        _backgroundView = [[TMView alloc] initWithFrame:self.bounds];
        
        _backgroundView.backgroundColor = NSColorFromRGBWithAlpha(0x000000, 0.8);
        
        [self addSubview:_backgroundView];
        
        
        _containerView = [[TMView alloc] initWithFrame:NSMakeRect(0, 0, 350, 250)];
        
        _containerView.backgroundColor = [NSColor whiteColor];
        
        [_containerView setCenterByView:self];
        
        _containerView.wantsLayer = YES;
        _containerView.layer.cornerRadius = 4;
        
        [self addSubview:_containerView];
        
    
        
        self.autoresizingMask = _backgroundView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        
        _containerView.autoresizingMask = NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin | NSViewMaxYMargin;
        
        _tableView = [[TMTableView alloc] initWithFrame:NSMakeRect(5, 5, NSWidth(_containerView.frame) - 10, NSHeight(_containerView.frame) - 10)];
        
        [_containerView addSubview:_tableView.containerView];
        
        _tableView.tm_delegate = self;
        
    }
    
    return self;
}

-(void)prepareAttachmentViews:(NSArray *)attachments {
    
    _currentResponderId = 0;
    
    NSMutableArray *items = [[NSMutableArray alloc] initWithCapacity:attachments.count];
    
    [attachments enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        TGAttachCaptionRowItem *item = [[TGAttachCaptionRowItem alloc] initWithObject:obj];
        item.controller = self;
        [items addObject:item];
        
    }];
    
    
    [_tableView removeAllItems:YES];
    
    [_tableView insert:items startIndex:0 tableRedraw:YES];
    
    
    int containerCount = floor((NSHeight(self.frame) - 50)/70);
    
    containerCount = MIN((int)_tableView.count,containerCount);
    
    [_containerView setFrameSize:NSMakeSize(NSWidth(_containerView.frame), containerCount*70 + 10)];
    
    [_tableView.containerView setFrame:NSMakeRect(5, 5, NSWidth(_containerView.frame) - 10, NSHeight(_containerView.frame) - 10)];
    
    [_containerView setCenterByView:self];
    
    int y = NSMinY(_containerView.frame);
    
    
    [_containerView setFrameOrigin:NSMakePoint(NSMinX(_containerView.frame), -NSHeight(_containerView.frame))];
    
    
    [_containerView setAlphaValue:0];
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        
        [[_containerView animator] setAlphaValue:1];
        [[_containerView animator] setFrameOrigin:NSMakePoint(NSMinX(_containerView.frame), y)];
        
    } completionHandler:^{
        
    }];
    
}

- (CGFloat)rowHeight:(NSUInteger)row item:(TMRowItem *) item {
    return 70;
}

- (BOOL)isGroupRow:(NSUInteger)row item:(TMRowItem *) item {
    return NO;
}

- (TMRowView *)viewForRow:(NSUInteger)row item:(TMRowItem *) item {
    
    TGAttachCaptionRowView *view = (TGAttachCaptionRowView *)[self.tableView cacheViewForClass:[TGAttachCaptionRowView class] identifier:@"TGAttachCaptionRowView" withSize:NSMakeSize(NSWidth(_tableView.frame), 70)];
    
    if(row == _currentResponderId) {
        [view becomeFirstResponder];
    }
    
    return view;
}

- (void)selectionDidChange:(NSInteger)row item:(TMRowItem *) item {
    
}

- (BOOL)selectionWillChange:(NSInteger)row item:(TMRowItem *) item {
    return NO;
}

- (BOOL)isSelectable:(NSInteger)row item:(TMRowItem *) item {
    return NO;
}

-(BOOL)becomeFirstResponder {
    if(self.tableView.list.count > _currentResponderId) {
        return [[self.tableView viewAtColumn:0 row:_currentResponderId makeIfNecessary:NO] becomeFirstResponder];
    }
    
    return YES;
}

-(void)mouseDown:(NSEvent *)theEvent {
    
}


-(void)mouseUp:(NSEvent *)theEvent {
    //[super mouseDown:theEvent];
    
    
    if(_tableView.count > 0) {
        TGAttachCaptionRowItem *item = (TGAttachCaptionRowItem *) self.tableView.list[0];
        [item.attach.item save];
    }
    
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        
        [[_containerView animator] setAlphaValue:0];
        [[_containerView animator] setFrameOrigin:NSMakePoint(NSMinX(_containerView.frame), -NSHeight(_containerView.frame))];
        
    } completionHandler:^{
        
    }];
    
    dispatch_after_seconds(0.2, ^{

        
        if(_onClose) {
            _onClose();
            _onClose = nil;
        }
        
        
        [TMViewController hideAttachmentCaption];
        
    });
    
}

-(void)setFrameSize:(NSSize)newSize {
    [super setFrameSize:newSize];
    
    int containerCount = floor((NSHeight(self.frame) - 50)/70);
    
    containerCount = MIN((int)_tableView.count,containerCount);
    
    if(NSHeight(_containerView.frame) == containerCount*70 + 10)
        return;
    
    
    [_containerView setFrameSize:NSMakeSize(NSWidth(_containerView.frame), containerCount*70 + 10)];
    
    [_tableView.containerView setFrame:NSMakeRect(5, 5, NSWidth(_containerView.frame) - 10, NSHeight(_containerView.frame) - 10)];
    
    [_containerView setCenterByView:self];

}


-(void)changeResponder {
    
    _currentResponderId++;
    
    if(_currentResponderId == _tableView.count) {
        [self mouseUp:nil];
    } else {
    
        [self becomeFirstResponder];
    }
    
}


-(void)scrollWheel:(NSEvent *)theEvent {
    
}



-(void)keyDown:(NSEvent *)theEvent {
    if(theEvent.keyCode == 53) {
        [self mouseUp:theEvent];
    }
}

@end
