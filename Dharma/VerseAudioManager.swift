import AVFoundation
import Combine

enum VersePlaybackState: Equatable {
    case idle
    case buffering
    case playing
    case paused
    case failed
}

final class VerseAudioManager: ObservableObject {
    static let shared = VerseAudioManager()

    @Published var state: VersePlaybackState = .idle
    @Published var currentReference: String = ""

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var statusObservation: NSKeyValueObservation?
    private var rateObservation: NSKeyValueObservation?
    private var cancellables = Set<AnyCancellable>()

    private static let baseURL = "https://raw.githubusercontent.com/gita/gita/main/data/verse_recitation"

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func play(chapter: Int, verse: Int) {
        let ref = "\(chapter).\(verse)"

        if currentReference == ref, state == .paused, let player {
            player.play()
            state = .playing
            return
        }

        stop()
        currentReference = ref
        state = .buffering

        let urlString = "\(Self.baseURL)/\(chapter)/\(verse).mp3"
        guard let url = URL(string: urlString) else {
            state = .failed
            return
        }

        let item = AVPlayerItem(url: url)
        let avPlayer = AVPlayer(playerItem: item)
        self.player = avPlayer

        statusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                switch item.status {
                case .readyToPlay:
                    avPlayer.play()
                    self.state = .playing
                case .failed:
                    self.state = .failed
                default:
                    break
                }
            }
        }

        rateObservation = avPlayer.observe(\.rate, options: [.new]) { [weak self] player, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                if player.rate == 0, self.state == .playing {
                    self.state = .idle
                    self.currentReference = ""
                }
            }
        }

        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: item)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.state = .idle
                self?.currentReference = ""
            }
            .store(in: &cancellables)
    }

    func pause() {
        player?.pause()
        state = .paused
    }

    func togglePlayPause(chapter: Int, verse: Int) {
        switch state {
        case .playing:
            pause()
        case .paused where currentReference == "\(chapter).\(verse)":
            player?.play()
            state = .playing
        default:
            play(chapter: chapter, verse: verse)
        }
    }

    func stop() {
        player?.pause()
        statusObservation?.invalidate()
        rateObservation?.invalidate()
        cancellables.removeAll()
        player = nil
        state = .idle
        currentReference = ""
    }
}
