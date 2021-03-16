//
//  ProxyHandler.swift
//  WebViewProxy
//
//  Created by VictorChee on 2021/3/15.
//

import Foundation
import WebKit

fileprivate let httpProxyKey = kCFNetworkProxiesHTTPEnable as String
fileprivate let httpHostKey = kCFNetworkProxiesHTTPProxy as String
fileprivate let httpPortKey = kCFNetworkProxiesHTTPPort as String
fileprivate let httpsProxyKey = "HTTPSEnable"
fileprivate let httpsHostKey = "HTTPSProxy"
fileprivate let httpsPortKey = "HTTPSPort"

// 参考 https://nemocdz.github.io/post/ios-设置代理proxy方案总结/
// 本来这个是WKWebView用来加载不认识的scheme链接资源的，这里通过Hook把这个限制去掉，普通的HTTP和HTTPS流量也通过这里来处理
// WKWebView不支持直接设置请求代理，只有URLSession可以
// WKWebView也不支持URLProtocol这种全局代理
class ProxyHandler: NSObject {
    private let session: URLSession = {
        let host = "x.x.x.x" // 代理地址
        let port = 8888 // 代理端口
        let proxy: [String: Any] = [
            httpProxyKey: true,
            httpHostKey: host,
            httpPortKey: port,
            httpsProxyKey: true,
            httpsHostKey: host,
            httpsPortKey: port
        ] // 分别代理HTTP和HTTPS
        let configuration = URLSessionConfiguration.default
        configuration.connectionProxyDictionary = proxy // 设置请求代理
        
        return URLSession(configuration: configuration)
    }() // 共享使用URLSession
    
    private var dataTask: URLSessionDataTask?
}

extension ProxyHandler: WKURLSchemeHandler {
    // 开始处理schemeTask
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        dataTask = session.dataTask(with: urlSchemeTask.request, completionHandler: { [weak urlSchemeTask] (data, response, error) in
            guard let urlSchemeTask = urlSchemeTask else { return }
            // 把代理获得的数据喂给WKWebView
            if let error = error {
                urlSchemeTask.didFailWithError(error)
            } else {
                if let response = response {
                    urlSchemeTask.didReceive(response)
                }
                if let data = data {
                    urlSchemeTask.didReceive(data)
                }
                urlSchemeTask.didFinish()
            }
        })
        dataTask?.resume()
    }
    
    // 停止schemeTask
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        dataTask?.cancel()
    }
}

extension WKWebViewConfiguration {
    // 注册HTTP和HTTPS代理配置，这两种Scheme都走ProxyHandler
    // 默认不让改变HTTP和HTTPS的代理，因为是系统处理的，这里需要通过Hook把这个限制去掉，详见WKWebView+Hook
    static var proxyConfiguration: WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        let handler = ProxyHandler()
        configuration.setURLSchemeHandler(handler, forURLScheme: "http")
        configuration.setURLSchemeHandler(handler, forURLScheme: "https")
        return configuration
    }
}
