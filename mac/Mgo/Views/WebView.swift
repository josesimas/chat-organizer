//
//  WebView.swift
//  Mgo
//
//  Created by Jose Dias on 29/12/2023.
//
import SwiftUI
import WebKit

class WebViewState: ObservableObject {
    @Published var webView: WKWebView


    init(urlString: String) {
        webView = WebViewState.createWebView(urlString: urlString)
    }

    private static func createWebView(urlString: String) -> WKWebView {
        let userContentController = WKUserContentController()

        // JavaScript to override console.log
        let scriptSource = """
        console.log = function(message) {
            window.webkit.messageHandlers.logHandler.postMessage(message);
        };
        """
        let script = WKUserScript(source: scriptSource, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        userContentController.addUserScript(script)

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController

        let webView = WKWebView(frame: .zero, configuration: configuration)
        

        userContentController.add(WebViewMessageHandler(), name: "logHandler")

        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        return webView
    }

    private func loadInitialPage(url: URL) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    private func loadInitialPage(urlString: String) {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
}

struct WebView: NSViewRepresentable {
    var webView: WKWebView
    
    func makeNSView(context: Context) -> WKWebView {
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
       
    }
}

class WebViewMessageHandler: NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "logHandler", let messageBody = message.body as? String {
            print("JavaScript console.log: \(messageBody)")
        }
    }
}
