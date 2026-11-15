//
//  ContentBlockerRequestHandler.swift
//  ShortformBeGoneSafariBlocker
//
//  Hands Safari the rule list. Safari compiles it and applies it itself; this
//  extension never sees any page or address.
//

import Foundation

final class ContentBlockerRequestHandler: NSObject, NSExtensionRequestHandling {

    func beginRequest(with context: NSExtensionContext) {
        do {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("blockerList.json")
            try ContentBlockerRules.json().write(to: url, options: .atomic)
            guard let attachment = NSItemProvider(contentsOf: url) else {
                throw CocoaError(.fileReadUnknown)
            }
            let item = NSExtensionItem()
            item.attachments = [attachment]
            context.completeRequest(returningItems: [item], completionHandler: nil)
        } catch {
            context.cancelRequest(withError: error)
        }
    }
}
