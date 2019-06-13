//
//  PSSGetImage.m
//  AliyunPlayer_iOS_UI_pod
//
//  Created by 彭盛凇 on 2019/6/13.
//

#import "PSSGetImage.h"

@implementation PSSGetImage

+ (nullable UIImage *)imageNamed:(NSString *)name {
    
    NSBundle *currentBundle = [NSBundle bundleForClass:[self class]];
    
    NSDictionary *dic = currentBundle.infoDictionary;
    
    NSString *bundleName = [dic objectForKey:@"CFBundleExecutable"];
    
    NSInteger scale = [UIScreen mainScreen].scale;
    
    NSString *imageName = [NSString stringWithFormat:@"%@@%dx.png",name,scale == 3 ? 3 : 2];
    
    NSString *path = [currentBundle pathForResource:imageName ofType:nil inDirectory:[NSString stringWithFormat:@"%@.bundle", bundleName]];
    
    return [UIImage imageWithContentsOfFile:path];
    
}

@end
