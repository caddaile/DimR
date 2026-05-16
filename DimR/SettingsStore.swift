import Foundation

struct AppSettings: Codable {
    var isEnabled: Bool = true
    var activeDimOpacity: Double = 0.0
    var overlayOpacity: Double = 0.7
    var idleTimeout: Double = 60.0
}

final class SettingsStore {
    private let fileURL: URL
    private let decoder = JSONDecoder()
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    init(fileManager: FileManager = .default) {
        let applicationSupportURL = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]

        let directoryURL = applicationSupportURL.appendingPathComponent(
            "DimR",
            isDirectory: true
        )

        self.fileURL = directoryURL.appendingPathComponent("settings.json")
    }

    func load() -> AppSettings {
        guard let data = try? Data(contentsOf: fileURL) else {
            return AppSettings()
        }

        return (try? decoder.decode(AppSettings.self, from: data)) ?? AppSettings()
    }

    func save(_ settings: AppSettings) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let data = try encoder.encode(settings)
        try data.write(to: fileURL, options: .atomic)
    }
}
