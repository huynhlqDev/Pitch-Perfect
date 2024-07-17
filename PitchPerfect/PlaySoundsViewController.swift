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

enum PlayingState {
    case playing
    case notPlaying
}

internal final class PlaySoundsViewController: UIViewController {
    // MARK: Properties

    private var playType: PlayType = .normal
    var audioUrl: URL!
    var audioFile: AVAudioFile!
    var audioEngine: AVAudioEngine!
    var audioPlayNode: AVAudioPlayerNode!
    var stopTimer: Timer!

    private var isPlaying: Bool = false

    // MARK: Life cycle

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAudio()
    }

    // MARK: IBAction

    @IBAction private func onTapSlowButton(_ sender: Any) {
        print(#function)
        playSound(rate: 0.5)
    }

    @IBAction private func onTapFastButton(_ sender: Any) {
        print(#function)
        playSound(rate: 1.5)
    }

    @IBAction private func onTapHighPitchButton(_ sender: Any) {
        print(#function)
        playSound(pitch: 1000)
    }

    @IBAction private func onTapLowPitchButton(_ sender: Any) {
        print(#function)
        playSound(pitch: -1000)
    }

    @IBAction private func onTapEchoButton(_ sender: Any) {
        print(#function)
        playSound(echo: true)
    }

    @IBAction private func onTapReverbButton(_ sender: Any) {
        print(#function)
        playSound(reverb: true)
    }

    @IBAction private func onTapStopButton(_ sender: Any) {
        print(#function)
        stopAudio()
    }

    @objc
    func stopAudio() {
        if let audioPlayNode = audioPlayNode {
            audioPlayNode.stop()
        }

        if let stopTimer = stopTimer {
            stopTimer.invalidate()
        }

        if let audioEngine = audioEngine {
            audioEngine.stop()
            audioEngine.reset()
        }
    }
}

extension PlaySoundsViewController {

    private func setupAudio() {
        do {
            audioFile = try AVAudioFile(forReading: audioUrl as URL)
        } catch {
            print(error)
        }
    }

    private func connectAudioNodes(_ nodes: AVAudioNode...) {
        for x in 0..<nodes.count-1 {
            audioEngine.connect(nodes[x], to: nodes[x+1], format: audioFile.processingFormat)
        }
    }

    private func configureUI(_ playState: Bool) {
        print(isPlaying)
    }

    private func playSound(
        rate: Float? = nil,
        pitch: Float? = nil,
        echo: Bool = false,
        reverb: Bool = false
    ) {
        audioEngine = AVAudioEngine()
        audioPlayNode = AVAudioPlayerNode()
        audioEngine.attach(audioPlayNode)

        // for pitch/rate
        let changeRatePitchNode = AVAudioUnitTimePitch()
        if let pitch = pitch {
            changeRatePitchNode.pitch = pitch
        }
        if let rate = rate {
            changeRatePitchNode.rate = rate
        }

        audioEngine.attach(changeRatePitchNode)

        // for echo
        let echoNode = AVAudioUnitDistortion()
        echoNode.loadFactoryPreset(.multiEcho1)
        audioEngine.attach(echoNode)

        // for reverb
        let reverbNode = AVAudioUnitReverb()
        reverbNode.loadFactoryPreset(.cathedral)
        reverbNode.wetDryMix = 50
        audioEngine.attach(reverbNode)

        // connect nodes
        switch (echo, reverb) {
        case (true,true):
            connectAudioNodes(audioPlayNode, changeRatePitchNode, echoNode, reverbNode, audioEngine.outputNode)
        case (true, false):
            connectAudioNodes(audioPlayNode, changeRatePitchNode, echoNode, audioEngine.outputNode)
        case (false, true):
            connectAudioNodes(audioPlayNode, changeRatePitchNode, reverbNode, audioEngine.outputNode)
        case (false, false):
            connectAudioNodes(audioPlayNode, changeRatePitchNode, audioEngine.outputNode)
        }

        // schedule to play and start the engine
        audioPlayNode.stop()
        audioPlayNode.scheduleFile(audioFile, at: nil) {
            var delayInSeconds: Double = 0

            if let lastRenderTime = self.audioPlayNode.lastRenderTime,
               let playerTime = self.audioPlayNode.playerTime(forNodeTime: lastRenderTime) {
                if let rate = rate {
                    delayInSeconds = Double(self.audioFile.length - playerTime.sampleTime) / Double(self.audioFile.processingFormat.sampleRate) / Double(rate)
                } else {
                    delayInSeconds = Double(self.audioFile.length - playerTime.sampleTime) / Double(self.audioFile.processingFormat.sampleRate)
                }
            }

            self.stopTimer = Timer(timeInterval: delayInSeconds, target: self, selector: #selector(PlaySoundsViewController.stopAudio), userInfo: nil, repeats: false)
            RunLoop.main.add(self.stopTimer, forMode: .default)
        }

        do {
            try audioEngine.start()
        } catch {
            return
        }

        audioPlayNode.play()
    }
}
