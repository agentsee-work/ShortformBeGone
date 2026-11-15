//
//  SafariWebExtensionHandler.swift
//  ShortformBeGoneSafariGuard
//
//  The guard is a Safari web extension whose whole job is done by content.js,
//  which runs inside the pages of the sites it covers. Safari requires this
//  class to exist; the script never sends it a message.
//

import Foundation

final class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
        context.completeRequest(returningItems: [], completionHandler: nil)
    }
}
