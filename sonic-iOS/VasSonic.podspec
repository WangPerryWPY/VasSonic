Pod::Spec.new do |spec|
	spec.name         = "VasSonic"
	spec.version      = "3.1.1"
	spec.summary      = "A Lightweight And High-performance Hybrid Framework."
	spec.description  = "VasSonic is a lightweight and high-performance Hybrid framework developed by tencent VAS team, which is intended to speed up the first screen of websites working on Android and iOS platform."
	spec.homepage     = "https://github.com/Tencent/VasSonic"
	spec.license      = "MIT"
	spec.author       = "Tencent"
	spec.platform     = :ios, "9.0"
	spec.source       = { :git => "https://github.com/Tencent/VasSonic.git", :tag => "#{spec.version}" }
	spec.source_files  = "Sonic", "Sonic/**/*.{h,m,mm}"
	spec.public_header_files = "Sonic/**/*.h"
	spec.requires_arc = false
	spec.ios.vendored_framework = "Classes/BMWAppKit.framework","Classes/RAPI.framework"
	spec.resource  = 'Classes/*.bundle'
	spec.libraries = "sqlite3"
	spec.pod_target_xcconfig = {
		"CLANG_ENABLE_OBJC_WEAK": "YES",
		"OTHER_CFLAGS": "-fembed-bitcode"
	}
end
