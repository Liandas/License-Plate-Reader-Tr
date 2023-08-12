//
//  Timer.swift
//  LicensePlateReader
//
//  Created by Arda Doğantemur on 12.08.2023.
//

import Foundation

class Timer
{
    var time = Date().timeIntervalSince1970 * 1000

    func isTimePassed(milisec: TimeInterval) -> Bool {
        let currentTime = Date().timeIntervalSince1970 * 1000
        if((currentTime - time) > milisec)
        {
            time = currentTime
            return true
        }
        return false
    }

}
