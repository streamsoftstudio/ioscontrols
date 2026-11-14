//
//  MessageBannerTiming.swift
//  IOSControls
//
//  Created by Andrija Milovanovic on 14.11.2026.
//

import Foundation

/// How long a banner stays on screen: long enough to notice it and read it,
/// and longer while VoiceOver speaks it.
public enum MessageBannerTiming {

    /// The least a banner stays, in seconds.
    public static let shortest: TimeInterval = 4

    /// The most a banner stays for its text alone, in seconds.
    public static let longest: TimeInterval = 10

    /// To notice the banner before reading it, in seconds.
    static let noticing: TimeInterval = 1.5

    /// To read a word, in seconds: a little slower than most people read.
    static let perWord: TimeInterval = 0.3

    /// How many times longer a banner stays while VoiceOver runs, which
    /// speaks it after whatever it is saying already.
    static let voiceOverFactor: Double = 2

    /// How long a banner holding `text` stays.
    public static func duration(forText text: String, voiceOverRunning: Bool) -> TimeInterval {
        let words = text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
        let reading = min(max(noticing + Double(words) * perWord, shortest), longest)
        return voiceOverRunning ? reading * voiceOverFactor : reading
    }
}
