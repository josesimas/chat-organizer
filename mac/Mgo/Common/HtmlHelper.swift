//
//  HtmlHelper.swift
//  Mgo
//
//  Created by Jose Dias on 18/12/2023.
//

import Foundation
import Ink

struct HtmlHelper {
    
    public static func getConversationAsPlainHtml(path: String, uuid: String, showToolsAndSystem: Bool) -> String {
        
        let dm = DatabaseManager(databasePath: path)
        let messages = dm.getConversationRepo().getConversationAsList(conversationUuid: uuid)
        let assistantName = dm.getAssistantName(conversationUuid: uuid)
        var htmlBlocks: [String] = []
        
        let filteredMessages = showToolsAndSystem ? messages : messages.filter { $0.type != "SYSTEM" && $0.type != "TOOL" }

        for message in filteredMessages {
            if message.text == "" {
                continue
            }
           
            var parser = MarkdownParser()
            let code = Modifier(target: .codeBlocks) { html, markdown in
                if html.contains("<pre><code class=") {
                    return html.replacingOccurrences(of: "<pre><code class=", with: "<pre><code class='code-text' style='border: 1px solid #ccc; padding: 10px; box-shadow: 1px 1px 2px #eee; display: block; font-size:16px' class=")
                }
                if html.contains("<pre><code>") {
                    return html.replacingOccurrences(of: "<pre><code>", with: "<pre><code class='code-text' style='border: 1px solid #ccc; padding: 10px; box-shadow: 1px 1px 2px #eee; display: block; font-size:16px'>")
                }
                return html
            }
            parser.addModifier(code)
            let mk = "**\(message.type)**\n\n\(message.text)"
            htmlBlocks.append(parser.html(from: mk))
        }
        
        let htmlFinal = "<head>\(getStyle())</head><body onload='onWindowLoad();'>\n"
            + "<h3>\(assistantName)</h3>\n\(htmlBlocks.joined())\n</body>"
        //Info.add(htmlFinal)
        return htmlFinal
    }
    
    public static func getConversationAsHtml(path: String, uuid: String, searchString: String, showToolsAndSystem: Bool) -> String {
        
        if(uuid == "") {
            return ""
        }
                    
        let dm = DatabaseManager(databasePath: path)
        let messages = dm.getConversationRepo().getConversationAsList(conversationUuid: uuid)
        let assistantName = dm.getAssistantName(conversationUuid: uuid)
        var htmlBlocks: [String] = []
        
        let filteredMessages = showToolsAndSystem ? messages : messages.filter { $0.type != "SYSTEM" && $0.type != "TOOL" }
        var counter = 0
        for message in filteredMessages {
            if message.text == "" {
                continue
            }
            let copyIcon = """
<button class='button copy-button' data-id='\(counter)' onclick='copyCodeToClipboard(\(counter))' title='Copy'><svg id='svg\(counter)' width='24' height='24' viewBox='0 0 24 24' fill='none' xmlns='http://www.w3.org/2000/svg' class='icon-sm'><path fill-rule='evenodd' clip-rule='evenodd' d='M12 4C10.8954 4 10 4.89543 10 6H14C14 4.89543 13.1046 4 12 4ZM8.53513 4C9.22675 2.8044 10.5194 2 12 2C13.4806 2 14.7733 2.8044 15.4649 4H17C18.6569 4 20 5.34315 20 7V19C20 20.6569 18.6569 22 17 22H7C5.34315 22 4 20.6569 4 19V7C4 5.34315 5.34315 4 7 4H8.53513ZM8 6H7C6.44772 6 6 6.44772 6 7V19C6 19.5523 6.44772 20 7 20H17C17.5523 20 18 19.5523 18 19V7C18 6.44772 17.5523 6 17 6H16C16 7.10457 15.1046 8 14 8H10C8.89543 8 8 7.10457 8 6Z' fill='gray'></path></svg></button>
"""
            var parser = MarkdownParser()
            let code = Modifier(target: .codeBlocks) { html, markdown in
                if html.contains("<pre><code class=") {
                    return html.replacingOccurrences(of: "<pre><code class=", with: "<div style='text-align: right'>\(copyIcon)</div><pre><code data-id='\(counter)' class='code-text' style='border: 1px solid #ccc; padding: 10px; box-shadow: 1px 1px 2px #eee; display: block; font-size:16px' class=")
                }
                if html.contains("<pre><code>") {
                    return html.replacingOccurrences(of: "<pre><code>", with: "<div style='text-align: right'>\(copyIcon)</div><pre><code data-id='\(counter)' class='code-text' style='border: 1px solid #ccc; padding: 10px; box-shadow: 1px 1px 2px #eee; display: block; font-size:16px'>")
                }
                return html
            }
            parser.addModifier(code)
            let mk = "**\(message.type)**\n\n\(message.text)"
            htmlBlocks.append(parser.html(from: mk))
            
            counter += 1
        }

        //change color of the types' headers
        let htmlContent = htmlBlocks.joined()
            .replacingOccurrences(of: "<strong>USER</strong>", with: "<h4 style='color: gray;'>USER</h4>")
            .replacingOccurrences(of: "<strong>ASSISTANT</strong>", with: "<h4 style='color: gray;'>ASSISTANT</h4>")
            .replacingOccurrences(of: "<strong>TOOL</strong>", with: "<h4 style='color: gray;'>TOOL</h4>")
            .replacingOccurrences(of: "<strong>SYSTEM</strong>", with: "<h4 style='color: gray;'>SYSTEM</h4>")
        
        let jsFunctions =
        """
<script>
function onWindowLoad() {
    scrollToBookmark()
}

function scrollToBookmark() {
    var bookmarks = document.getElementsByClassName('highlighted');
    if (bookmarks.length > 0) {
        bookmarks[\("0")].scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
}

function copyCodeToClipboard(id) {
    
    const textToCopy = document.querySelector('code[data-id="' + id + '"]').textContent;
    var dummy = document.createElement('textarea');
    document.body.appendChild(dummy);
    dummy.value = textToCopy;
    dummy.select();
    document.execCommand('copy');
    document.body.removeChild(dummy);
    
    var svg = document.getElementById("svg" + id);
    svg.setAttribute('stroke', 'green');
    setTimeout(function() {
        svg.setAttribute('stroke', '');
    }, 500)
}
"""
        if searchString.count > 1 {
            let trimmedSearch = searchString.trimmingCharacters(in: .whitespacesAndNewlines)
            let htmlFinal = "<head>\(getStyle())\n</head><body onload='onWindowLoad();'>\n"
                + "<h3 style='color: gray;'>\(assistantName)</h3>"
                + highlightOccurrences(in: htmlContent, searchString: trimmedSearch)
                + "\n</body>\n" + jsFunctions
            //Info.add(htmlFinal)
            return htmlFinal
        } else {
            let htmlFinal = "<head>\(getStyle())</head><body onload='onWindowLoad();'>\n"
                + "<h3 style='color: gray;'>\(assistantName)</h3>\n\(htmlContent)\n\(jsFunctions)\n</body>"
            //Info.add(htmlFinal)
            return htmlFinal
        }
    }
        
    static func highlightOccurrences(in html: String, searchString: String) -> String {
        let highlightedHtml = html.replacingOccurrences(
            of: searchString,
            with: "<span style='background-color: yellow;' class='highlighted'>\(searchString)</span>",
            options: .caseInsensitive,
            range: nil)
        return highlightedHtml
    }
    
    static func getStyle() -> String {
        """
        <style>
            .button:hover {
            cursor: pointer;
            }

            .copy-button {
                background-color:transparent;
                border:none;
            }
        </style>
        """
    }
}
