//
//  ViewController.swift
//  WebViewProxy
//
//  Created by VictorChee on 2021/3/15.
//

import UIKit
import WebKit

class ViewController: UIViewController {
    private var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        webView = WKWebView(frame: view.frame, configuration: WKWebViewConfiguration.proxyConfiguration)
        view.addSubview(webView)
        
        let url = URL(string: "https://steamcommunity.com/login")!
        let request = URLRequest(url: url)
        webView.load(request)
    }
}
