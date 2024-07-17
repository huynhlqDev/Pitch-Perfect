//
//  PlaySoundViewController.swift
//  PitchPerfect
//
//  Created by huynh on 17/7/24.
//

import UIKit
import AVFoundation

internal final class PlaySoundsViewController: UIViewController {

    // MARK: @IBOutlet

    @IBOutlet weak private var slowButton: UIButton!
    @IBOutlet weak private var fastButton: UIButton!
    @IBOutlet weak private var hightPitchButton: UIButton!
    @IBOutlet weak private var lowPitchButton: UIButton!
    @IBOutlet weak private var echoButton: UIButton!
    @IBOutlet weak private var reverbButton: UIButton!
    @IBOutlet weak private var stopButton: UIButton!

    // MARK: Properties

    var audioUrl: URL!
    var audioFile: AVAudioFile!
    var audioEngine: AVAudioEngine!
    var audioPlayNode: AVAudioPlayerNode!
    var stopTimer: Timer!

    private var isPlaying: Bool = false {
        didSet {
            slowButton.isEnabled = !isPlaying
            fastButton.isEnabled = !isPlaying
            lowPitchButton.isEnabled = !isPlaying
            hightPitchButton.isEnabled = !isPlaying
            echoButton.isEnabled = !isPlaying
            reverbButton.isEnabled = !isPlaying
            stopButton.isEnabled = isPlaying
        }
    }

    // MARK: Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAudio()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAudio()
    }

    // MARK: IBAction

    @IBAction private func onTapSlowButton(_ sender: Any) {
        playSound(rate: 0.5)
    }

    @IBAction private func onTapFastButton(_ sender: Any) {
        playSound(rate: 1.5)
    }

    @IBAction private func onTapHighPitchButton(_ sender: Any) {
        playSound(pitch: 1000)
    }

    @IBAction private func onTapLowPitchButton(_ sender: Any) {
        playSound(pitch: -1000)
    }

    @IBAction private func onTapEchoButton(_ sender: Any) {
        playSound(echo: true)
    }

    @IBAction private func onTapReverbButton(_ sender: Any) {
        playSound(reverb: true)
    }

    @IBAction private func onTapStopButton(_ sender: Any) {
        stopAudio()
    }

    private func setupAudio() {
        do {
            audioFile = try AVAudioFile(forReading: audioUrl as URL)
        } catch {
            print(error)
        }
    }

    @objc
    func stopAudio() {
        isPlaying = false

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

    private func connectAudioNodes(_ nodes: AVAudioNode...) {
        for x in 0..<nodes.count-1 {
            audioEngine.connect(nodes[x], to: nodes[x+1], format: audioFile.processingFormat)
        }
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
        isPlaying = true
    }
}
