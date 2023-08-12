//
//  Helpers.swift
//  LicensePlateReader
//
//  Created by Arda Doğantemur on 12.08.2023.
//

import Foundation

class Helpers
{
    static func addPadding(to rect: CGRect, padding: CGFloat) -> CGRect {
        return CGRect(
            x: rect.origin.x - padding,
            y: rect.origin.y - padding,
            width: rect.size.width + 2 * padding,
            height: rect.size.height + 2 * padding
        )
    }
}
