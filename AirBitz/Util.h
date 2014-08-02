//
//  Util.h
//  AirBitz
//
//  Created by Adam Harris on 5/19/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBookUI/AddressBookUI.h>
#import "ABC.h"

@interface Util : NSObject

+ (NSString *)errorCodeMap:(int)code;
+ (void)printABC_Error:(const tABC_Error *)pError;
+ (void)resizeView:(UIView *)theView withDisplayView:(UIView *)theDisplayView;
+ (void)freeStringArray:(char **)aszStrings count:(unsigned int)count;
+ (NSString *)getNameFromAddressRecord:(ABRecordRef)person;

@end
