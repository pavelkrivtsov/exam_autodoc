import Foundation

extension URL {
    /// SFSafariViewController принимает только http/https с непустым host.
    var isSafariCompatible: Bool {
        guard let scheme = scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host, !host.isEmpty
        else { return false }
        return true
    }
}

