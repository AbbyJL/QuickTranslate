import SwiftUI
import AppKit
import Carbon


// MARK: - Status Bar Icon

func createStatusBarIcon() -> NSImage {
    let size = NSSize(width: 18, height: 18)
    let image = NSImage(size: size)
    image.lockFocus()

    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 14, weight: .medium),
        .foregroundColor: NSColor.black
    ]
    let str = NSAttributedString(string: "译", attributes: attrs)
    let strSize = str.size()
    str.draw(at: NSPoint(x: (size.width - strSize.width) / 2, y: (size.height - strSize.height) / 2))

    image.unlockFocus()
    image.isTemplate = true
    return image
}

// MARK: - Translation View Model

class TranslationViewModel: ObservableObject {
    @Published var originalText: String = ""
    @Published var translatedText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""

    func reset() {
        originalText = ""
        translatedText = ""
        isLoading = false
        errorMessage = ""
    }

    func translate(_ text: String) {
        originalText = text
        isLoading = true
        errorMessage = ""
        translatedText = ""

        TranslationService.shared.translate(text: text) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let translated):
                    self?.translatedText = translated
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Translation Service

class TranslationService {
    static let shared = TranslationService()

    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        session = URLSession(configuration: config)
    }

    func translate(text: String, completion: @escaping (Result<String, Error>) -> Void) {
        let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=zh-CN&dt=t&q=\(encodedText)"

        guard let url = URL(string: urlString) else {
            completion(.failure(TranslationError.invalidURL))
            return
        }

        session.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(TranslationError.noData))
                return
            }

            do {
                guard let json = try JSONSerialization.jsonObject(with: data) as? [Any],
                      let translations = json.first as? [[Any]] else {
                    completion(.failure(TranslationError.parseError))
                    return
                }

                let translatedText = translations.compactMap { $0.first as? String }.joined()
                if translatedText.isEmpty {
                    completion(.failure(TranslationError.emptyResult))
                } else {
                    completion(.success(translatedText))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

enum TranslationError: LocalizedError {
    case invalidURL
    case noData
    case parseError
    case emptyResult

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效的翻译请求"
        case .noData: return "未收到翻译结果"
        case .parseError: return "翻译结果解析失败"
        case .emptyResult: return "翻译结果为空"
        }
    }
}

// MARK: - Clipboard Monitor

class ClipboardMonitor {
    private var timer: Timer?
    private var lastChangeCount: Int
    private var lastCopyTime: TimeInterval = 0
    var onDoubleCopy: ((String) -> Void)?

    init() {
        lastChangeCount = NSPasteboard.general.changeCount
    }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        let currentChangeCount = pasteboard.changeCount

        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount

        let now = Date().timeIntervalSince1970
        let timeSinceLastCopy = now - lastCopyTime
        lastCopyTime = now

        // Double copy detected (two copies within 500ms)
        if timeSinceLastCopy < 0.5 {
            if let text = pasteboard.string(forType: .string), !text.isEmpty {
                onDoubleCopy?(text)
            }
        }
    }
}

// MARK: - Translation View

struct TranslationView: View {
    @ObservedObject var viewModel: TranslationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("翻译中...")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                } else if !viewModel.errorMessage.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("原文")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(viewModel.originalText)
                            .font(.system(size: 13))
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                        Divider()
                        Text("翻译失败")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.red)
                        Text(viewModel.errorMessage)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                } else if !viewModel.translatedText.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("原文")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(viewModel.originalText)
                            .font(.system(size: 13))
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                        Divider()
                        Text("译文")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(viewModel.translatedText)
                            .font(.system(size: 14, weight: .medium))
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                        Text("连续按两次 ⌘C 翻译选中文本")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }

            Divider()

            HStack {
                Spacer()
                Button(action: {
                    NSApp.terminate(nil)
                }) {
                    Text("退出")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
        .frame(width: 320)
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var clipboardMonitor: ClipboardMonitor!
    let viewModel = TranslationViewModel()
    var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from dock
        NSApp.setActivationPolicy(.accessory)

        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = createStatusBarIcon()
            button.action = #selector(togglePopover)
            button.target = self
        }

        // Create popover
        let contentView = TranslationView(viewModel: viewModel)
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 60)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
        popover.contentViewController?.view.setFrameSize(NSSize(width: 320, height: 60))

        // Close popover when clicking outside
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let self = self, self.popover.isShown {
                self.popover.performClose(nil)
            }
        }

        // Start clipboard monitor
        clipboardMonitor = ClipboardMonitor()
        clipboardMonitor.onDoubleCopy = { [weak self] text in
            DispatchQueue.main.async {
                self?.handleDoubleCopy(text: text)
            }
        }
        clipboardMonitor.start()
    }

    @objc func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func handleDoubleCopy(text: String) {
        viewModel.translate(text)
        showPopover()
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardMonitor?.stop()
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}

// MARK: - App Entry Point

@main
struct QuickTranslateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
