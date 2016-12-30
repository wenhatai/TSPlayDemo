//
//  ViewController.m
//  TSPlayDemo
//
//  Created by 张鹏宇 on 2016/12/29.
//  Copyright © 2016年 张鹏宇. All rights reserved.
//

#import "ViewController.h"
#import "GCDWebDAVServer.h"
#import "GCDWebServerDataResponse.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

#define DEFAULT_TS_URL "http://devimages.apple.com/iphone/samples/bipbop/gear1/fileSequence0.ts"
#define DEFAULT_TS_TIME 10

@interface ViewController (){
    UIActivityIndicatorView *_progressView;
    GCDWebDAVServer* _davServer;
    NSString *_documentsPath;
    NSString *_tsFileName;
    NSString *_m3U8Name;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _urlLable.text = @DEFAULT_TS_URL;
    _timeLable.text = [NSString stringWithFormat:@"%d",DEFAULT_TS_TIME];
    _progressView = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _progressView.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2);
    _progressView.backgroundColor = [UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:0.5];
    _progressView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    _progressView.hidesWhenStopped = TRUE;
    [self.view addSubview:_progressView];
    
    _documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    _davServer = [[GCDWebDAVServer alloc] initWithUploadDirectory:_documentsPath];
    [_davServer start];
    NSLog(@"serverURL：%@", _davServer.serverURL);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) showAlertView:(NSString *)msg{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:msg preferredStyle:  UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }]];
    [self presentViewController:alert animated:true completion:nil];
}

-(void) playTs{
    AVPlayerViewController *newPlayer = [[AVPlayerViewController alloc] init];
    NSString *serverAddress = [_davServer.serverURL.absoluteString stringByAppendingString:_m3U8Name];
    NSURL *url = [NSURL URLWithString:serverAddress];
    newPlayer.player = [[AVPlayer alloc]initWithURL:url];
    [self presentViewController:newPlayer animated:YES completion:^{
        [newPlayer.player play];
    }];
}

-(IBAction)confirmClick:(id)sender{
    NSString *tsUrl = _urlLable.text;
    NSString *tsTime = _timeLable.text;
    if([@"" isEqualToString:tsUrl] || [@"" isEqualToString:tsTime]){
        [self showAlertView:@"输入切片地址和时间"];
        return;
    }
    _tsFileName = [NSString stringWithFormat:@"%lu.ts",(unsigned long)tsUrl.hash];
    _m3U8Name = [NSString stringWithFormat:@"%lu.m3u8",(unsigned long)tsUrl.hash];
    //写入m3u8文件
    NSString *m3u8Path = [_documentsPath stringByAppendingPathComponent:_m3U8Name];
    NSString *content = @"#EXTM3U\n"
    "#EXT-X-VERSION:3\n"
    "#EXT-X-MEDIA-SEQUENCE:0\n"
    "#EXT-X-TARGETDURATION:20\n"
    "#EXTINF:%d,\n"
    "%@\n"
    "#EXT-X-ENDLIST";
    content = [NSString stringWithFormat:content,[tsTime intValue],_tsFileName];
    [content writeToFile:m3u8Path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    NSString *tsPath = [_documentsPath stringByAppendingPathComponent:_tsFileName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:tsPath]){
        [_progressView startAnimating];
        NSURLSession *session = [NSURLSession sharedSession];
        [[session dataTaskWithURL:[NSURL URLWithString:tsUrl]
                completionHandler:^(NSData *data,
                                    NSURLResponse *response,
                                    NSError *error) {
                    [_progressView stopAnimating];
                    if(error == nil){
                        [data writeToFile:tsPath atomically:NO];
                        [self playTs];
                    }else{
                        [self showAlertView:[error localizedDescription]];
                        NSLog(@"error:%@",[error localizedDescription]);
                    }
                }] resume];
    }else{
        [self playTs];
    }
}

@end
