let bundleProvider = """

private class BundleProvider {
    static let frameworkBundle = Bundle(for: BundleProvider.self).resourceURL?.appendingPathComponent("YDSKit.bundle")
    static let bundle = Bundle(url: frameworkBundle!)
}

"""
