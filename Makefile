all: sign

sign:
	cp Info.plist cmake-vscode-Debug/Bundle.app/Contents
	codesign -f --entitlement virt.entitlements -s - cmake-vscode-Debug/Bundle.app/Contents/MacOS/Bundle
