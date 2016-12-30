//
//  ViewController.swift
//  TSPlaySwiftDemo
//
//  Created by 张鹏宇 on 2016/12/29.
//  Copyright © 2016年 张鹏宇. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

let DEFAULT_TS_URL = "http://devimages.apple.com/iphone/samples/bipbop/gear1/fileSequence0.ts"
let DEFAULT_TS_TIME = 10
let M3U8_FORMAT_CONTENT = "#EXTM3U\n" +
        "#EXT-X-VERSION:3\n" +
        "#EXT-X-MEDIA-SEQUENCE:0\n" +
        "#EXT-X-TARGETDURATION:20\n" +
        "#EXTINF:%d,\n" +
        "%@\n" +
        "#EXT-X-ENDLIST"

class ViewController: UIViewController {
    @IBOutlet weak var urlLable: UITextField!
    @IBOutlet weak var timeLable: UITextField!
    @IBOutlet weak var confirmBtn: UIButton!
    let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
    var tsFileName:String?
    var m3U8Name:String?
    var davServer:GCDWebDAVServer?

    override func viewDidLoad() {
        super.viewDidLoad()
        urlLable.text = DEFAULT_TS_URL
        timeLable.text = String.init(format: "%d", DEFAULT_TS_TIME)
        davServer = GCDWebDAVServer.init(uploadDirectory: documentsPath)
        davServer?.start()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func playTs(){
        let serverAddress = davServer?.serverURL.URLByAppendingPathComponent(m3U8Name!)
        let player = AVPlayer.init(URL: serverAddress!)
        let playerViewController = AVPlayerViewController.init()
        playerViewController.player = player
        self.presentViewController(playerViewController, animated: true) {
            player.play()
        }
    }
    
    @IBAction func confirmClick(sender: AnyObject) {
        let tsUrl = urlLable.text
        let tsTime = timeLable.text
        if tsUrl == "" || tsTime == "" {
            self.noticeError("输入切片地址和时间", autoClear: true, autoClearTime: 2)
            return;
        }
        tsFileName = String.init(format: "%lu.ts", (tsUrl!.hash))
        m3U8Name = String.init(format: "%lu.m3u8", (tsUrl!.hash))
        if let time = Int(tsTime!){
            let content = String.init(format: M3U8_FORMAT_CONTENT, time, tsFileName!)
            let m3u8Path = (self.documentsPath as NSString).stringByAppendingPathComponent(m3U8Name!) as String
            do{
                try content.writeToFile(m3u8Path, atomically: true, encoding: NSUTF8StringEncoding)
            }catch {
                print(error)
            }
            let tsPath = (self.documentsPath as NSString).stringByAppendingPathComponent(tsFileName!) as String
            let fileManager = NSFileManager.defaultManager()
            if(!fileManager.fileExistsAtPath(tsPath)){
                pleaseWait()
                let session = NSURLSession.sharedSession()
                session.dataTaskWithURL(NSURL.init(string: tsUrl!)!, completionHandler: {data,_,sessionError in
                    self.clearAllNotice()
                    if sessionError == nil{
                        data?.writeToFile(tsPath, atomically: false)
                        self.playTs()
                    }else{
                        print("error:"+(sessionError?.localizedDescription)!)
                    }
                }).resume();
            }else{
                self.playTs()
            }
        }
    }

}

