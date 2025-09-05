import SwiftUI
import WebKit

struct HtmlView: NSViewRepresentable {
    let urlString: String
    var htmlContent: String?
    
    @Environment(\.colorScheme) var colorScheme
    
    func makeNSView(context: Context) -> WKWebView {
            let webView = WKWebView()
            loadContent(in: webView)
            return webView
        }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // Reload content if color scheme changes
        loadContent(in: nsView)
    }
    
    private func loadContent(in webView: WKWebView) {
        let theme = colorScheme == .dark ? "atom-one-dark.min.css" : "atom-one-light.min.css"

        if let htmlContent = htmlContent {
            let fullHTML = generateHTMLString(with: htmlContent, theme: theme, isDarkMode: colorScheme == .dark)
            webView.loadHTMLString(fullHTML, baseURL: nil)
        } else if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }

    private func generateHTMLString(with content: String, theme: String, isDarkMode: Bool) -> String {
        if content == "" {
            return ""
        }
        return """
               <html>
                   <head>
                       <meta name="viewport" content="width=device-width, initial-scale=1">
                       <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/\(theme)">
                       <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script>
                       <script>hljs.highlightAll();</script>
                       <style>
                           :root {
                               /* Define color variables for light and dark themes */
                               --background-color-light: #ffffff;
                               --background-color-dark: #1C1C1C;
                               --text-color-light: #000;
                               --text-color-dark: #fff;
                               --code-bg-light: #e9ecef;
                               --code-bg-dark: #495057;
                           }
                           body {
                               font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
                               line-height: 1.6;
                               padding: 20px;
                               margin: 0;
                               /* Use CSS variables for colors */
                               background-color: var(--background-color-light);
                               color: var(--text-color-light);
                           }
                           code {
                               background-color: var(--code-bg-light);
                               border-radius: 5px;
                               padding: 2px 5px;
                           }
                           pre code {
                               display: block;
                               padding: 15px;
                               overflow-x: auto;
                           }
                           .dark-theme {
                               --background-color-light: var(--background-color-dark);
                               --text-color-light: var(--text-color-dark);
                               --code-bg-light: var(--code-bg-dark);
                           }
                       </style>
                   </head>
                   <body>
                       \(content)

                       <script>
                           var isDarkMode = \(isDarkMode ? "true" : "false");

                           function applyTheme() {
                               if (isDarkMode) {
                                   document.body.classList.add('dark-theme');
                               } else {
                                   document.body.classList.remove('dark-theme');
                               }
                           }

                           // Call applyTheme on page load
                           applyTheme();
                       </script>
                   </body>
               </html>
               """
    }
}

struct SelectedText: Codable {
    let selectedText: String
    let messageUuid: String
}
