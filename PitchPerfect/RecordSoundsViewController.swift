//
//  ViewController.swift
//  PitchPerfect
//
//  Created by huynh on 17/7/24.
//

import UIKit
import AVFoundation

internal final class RecordSoundsViewController: UIViewController {

    // MARK: IBOutlet

    @IBOutlet weak private var recordButton: UIButton!
    @IBOutlet weak private var stopRecordingButton: UIButton!
    @IBOutlet weak private var recordingLabel: UILabel!

    // MARK: Properties
    private let openPlayScreenSegue = "stopRecording"

    private var audioRecorder: AVAudioRecorder!

    private var isRecoding: Bool = false {
        didSet {
            recordButton.isEnabled = !isRecoding
            stopRecordingButton.isEnabled = isRecoding
            recordingLabel.text = isRecoding ? "Recording in progress" : "Tap to record"
        }
    }

    // MARK: Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == openPlayScreenSegue {
            let playSoundsVC = segue.destination as! PlaySoundsViewController
            let audioUrl = sender as! URL
            playSoundsVC.audioUrl = audioUrl
        }
    }

    // MARK: IBAction

    @IBAction private func onTapRecordButton(_ sender: Any) {
        isRecoding = true
        print(#function)
        let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask, true)[0] as String
        let recordingName = "recordedVoice.wav"
        let pathArray = [dirPath, recordingName]
        let filePath = URL(string: pathArray.joined(separator: "/"))

        let session = AVAudioSession.sharedInstance()
        try! session.setCategory(
            AVAudioSession.Category.playAndRecord,
            mode: AVAudioSession.Mode.default,
            options: AVAudioSession.CategoryOptions.defaultToSpeaker
        )

        try! audioRecorder = AVAudioRecorder(url: filePath!, settings: [:])
        audioRecorder.delegate = self
        audioRecorder.isMeteringEnabled = true
        audioRecorder.prepareToRecord()
        audioRecorder.record()
    }

    @IBAction private func onTapStopButton(_ sender: Any) {
        isRecoding = false
        print(#function)
        audioRecorder.stop()
        let audioSession = AVAudioSession.sharedInstance()
        try! audioSession.setActive(false)
    }
    
}

extension RecordSoundsViewController: AVAudioRecorderDelegate {

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print(#function)
        if flag {
            performSegue(withIdentifier: openPlayScreenSegue, sender: audioRecorder.url)
        } else {
            print("recording was not successful")
        }
    }
}
