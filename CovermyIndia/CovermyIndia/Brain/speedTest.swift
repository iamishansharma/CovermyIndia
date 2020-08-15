//
//  speedTest.swift
//  CovermyIndia
//
//  Created by Ishan Sharma on 11/08/20.
//  Copyright © 2020 Ishan Sharma. All rights reserved.
//

import UIKit

class SpeedTest: UIViewController, URLSessionDelegate
{
    typealias speedTestCompletionHandler = (_ megabytesPerSecond: Double? , _ error: Error?) -> Void

    var speedTestCompletionBlock : speedTestCompletionHandler?

    var startTime: CFAbsoluteTime!
    var stopTime: CFAbsoluteTime!
    var bytesReceived: Int!

    func checkForSpeedTest()
    {

        testDownloadSpeedWithTimout(timeout: 5.0)
        {
            (speed, error) in
            print("Download Speed:", speed ?? "NA")
            print("Speed Test Error:", error ?? "NA")
        }

    }

    func testDownloadSpeedWithTimout(timeout: TimeInterval, withCompletionBlock: @escaping speedTestCompletionHandler)
    {

        guard let url = URL(string: "https://images.apple.com/v/imac-with-retina/a/images/overview/5k_image.jpg") else { return }

        startTime = CFAbsoluteTimeGetCurrent()
        stopTime = startTime
        bytesReceived = 0

        speedTestCompletionBlock = withCompletionBlock

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForResource = timeout
        let session = URLSession.init(configuration: configuration, delegate: self, delegateQueue: nil)
        session.dataTask(with: url).resume()

    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data)
    {
        bytesReceived! += data.count
        stopTime = CFAbsoluteTimeGetCurrent()
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
    {

        let elapsed = stopTime - startTime

        if let aTempError = error as NSError?, aTempError.domain != NSURLErrorDomain && aTempError.code != NSURLErrorTimedOut && elapsed == 0
        {
            speedTestCompletionBlock?(nil, error)
            return
        }

        let speed = elapsed != 0 ? (Double(bytesReceived)*Double(8) / elapsed / 1024.0 / 1024.0) : -1
        speedTestCompletionBlock?(speed, nil)
    }
}
