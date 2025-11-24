[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fcembaykara%2FPeekDialog%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/cembaykara/PeekDialog) [![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fcembaykara%2FPeekDialog%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/cembaykara/PeekDialog)
# 📦 PeekDialog 

PeekDialog is a lightweight and customizable SwiftUI component for displaying temporary, non-intrusive dialogs (or "peek dialogs") in your iOS apps. It supports automatic dismissal after a specified delay or manual dismissal via a drag gesture. Perfect for showing notifications, alerts, or other transient messages.

 <p align="center">
  <img src="images/screen.gif" alt="Screenshot 1" width="40%" style="border-radius:8px;"/>
  <img src="images/screen2.gif" alt="Screenshot 2" width="40%" style="border-radius:8px;"/>
</p>

## ✨ Features
- 📱 **iOS Compatibility**: Supports iOS 15 and above.
- ✨ **Glass Effect on iOS 26+**: ~~Automatically applies a glass effect when available.~~ This achieved now using `.dialogStyle(_ style:)` modifiers.
- ⏳ **Customizable Duration**: Choose from predefined durations (short, medium, long) or specify a custom duration.
- 👆 **Swipe to Dismiss**: Users can swipe the dialog away to dismiss it.
- 🖌️ **Flexible Content**: Use any SwiftUI view as the dialog's content.

## 🔧 Installation

##### Swift Package Managerv
 You can install the PeekDialog via Swift Package Manager.
 - In Xcode, add the PeekDialog by navigating to **File > Add Package Dependencies**
 - And enter the GitHub link: ```https://github.com/cembaykara/PeekDialog.git```

##### With Packages.swift

Add PeekDialog to your `Package.swift`:

```swift
dependencies: [ 
	.package(url: "https://github.com/cembaykara/PeekDialog.git", from: "1.0.0")
]
```

## 🚀 Usage

##### Using `isPresented`

You can present a dialog just like you would do with `.sheet(isPresented: )`

```swift
import SwiftUI
import PeekDialog

struct ContentView: View {
    @State private var showDialog = false

    var body: some View {
        VStack {
            Button("Show Peek Dialog") {
                showDialog = true
            }
        }
        .peekDialog(isPresented: $showDialog) {
            Text("This is a peek dialog!")
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .shadow(radius: 10)
        }
    }
}
```

##### Using an Optional Item

You can also bind the dialog to an optional item. The dialog will automatically show when the item is non-nil and dismiss when it becomes nil.

```swift
struct ContentView: View {

    @State private var myString: String? = nil

    var body: some View {
        VStack {
            Button("Show Dialog with Item") {
                activeItem = "Example Item"
            }
        }
        .peekDialog(with: $myString, dismissDelay: .long) { item in
             Text("Dialog for item: \(item)")
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .shadow(radius: 10)
        }
    }
}
```

##### Custom Duration

You can define a duration by using `PeekDialogDelay.custom(seconds: Double)`.

```swift
	.peekDialog(with: $myItem, dismissDelay: .custom(seconds: 1.25)) { item in
		/* ... */
	}
```

##### Custom Dialog Styles

You can customize the appearance of your dialogs using the `.dialogStyle(_ style:)` modifier. PeekDialog comes with a built-in `.glassRegular` and `.glassClear` styles for iOS 26+, or you can create your own custom styles.

```swift
struct ContentView: View {
    @State private var showDialog = false

    var body: some View {
        VStack {
            Button("Show Glass Dialog") {
                showDialog = true
            }
        }
        .peekDialog(isPresented: $showDialog) {
            VStack {
                Text("This dialog has a glass effect!")
            }
            .dialogStyle(.glassRegular)
        }
    }
}
```

## 🤝 Contributing

Contributions are welcome! If you find a bug or have a feature request, please open an issue. If you'd like to contribute code, fork the repository and submit a pull request.

  <a href='https://ko-fi.com/F1F719XC8H' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://storage.ko-fi.com/cdn/kofi6.png?v=6' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>

## ⚖️ License  

SwiftyEndpoint is released under the **[Apache License 2.0](LICENSE.md)**.  

See the **[LICENSE](LICENSE.md)** file for full details.