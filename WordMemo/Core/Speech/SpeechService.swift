import AVFoundation

/// 单词朗读服务（系统 TTS）
@Observable
final class SpeechService {
    private let synthesizer = AVSpeechSynthesizer()

    init() {
        // 使用 playback 会话，静音开关/勿扰模式下也能出声
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: .duckOthers)
        try? session.setActive(true)
    }

    func speak(_ text: String, rate: Float = 0.45) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = rate
        synthesizer.speak(utterance)
    }
}
