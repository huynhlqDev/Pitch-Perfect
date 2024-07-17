//
//  PlaySoundViewController.swift
//  PitchPerfect
//
//  Created by huynh on 17/7/24.
//

import UIKit
import AVFoundation

enum PlayType {
    case slow
    case fast
    case highPitch
    case lowPitch
    case echo
    case reverb
    case normal
}

internal final class PlaySoundsViewController: UIViewController {
    // MARK: Properties

    private var playType: PlayType = .normal
    var audioUrl: URL?

    // MARK: Life cycle

    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: IBAction

    @IBAction private func onTapSlowButton(_ sender: Any) {
        print(#function)
    }

    @IBAction private func onTapFastButton(_ sender: Any) {
        print(#function)
    }

    @IBAction private func onTapHighPitchButton(_ sender: Any) {
        print(#function)
    }

    @IBAction private func onTapLowPitchButton(_ sender: Any) {
        print(#function)
    }

    @IBAction private func onTapEchoButton(_ sender: Any) {
        print(#function)
    }

    @IBAction private func onTapReverbButton(_ sender: Any) {
        print(#function)
    }

    @IBAction private func onTapStopButton(_ sender: Any) {
        print(#function)
    }
}
