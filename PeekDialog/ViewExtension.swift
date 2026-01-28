//
//  ViewExtension.swift
//  PeekDialog
//
//  Created by Baris Cem Baykara on 03.02.2025.
//
import SwiftUI

public extension View {
    
    /// Displays a peek dialog with customizable content and dismissal behavior.
    ///
    /// This function attaches a `PeekDialog` modifier to a view, allowing you to present a dialog that can
    /// automatically dismiss itself after a specified delay or remain visible until explicitly dismissed.
    ///
    /// - Parameters:
    ///   - isPresented: A binding to a Boolean value that determines whether the dialog is currently presented.
    ///   - dismissDelay: The duration for which the dialog should remain visible before automatically dismissing.
    ///     Defaults to `.persistent`, meaning the dialog will stay visible until manually dismissed.
    ///   - placement: The vertical alignment of the dialog. Use `.top`, `.center`, or `.bottom`. Defaults to `.top`.
    ///   - content: The content to display inside the dialog.
    ///
    ///
    /// ## Example:
    ///   ```swift
    ///   @State private var showDialog = false
    ///
    ///   var body: some View {
    ///       Button("Show Dialog") {
    ///           showDialog = true
    ///       }
    ///       .peekDialog(isPresented: $showDialog, dismissDelay: .medium) {
    ///           Text("This is a peek dialog!")
    ///               .padding()
    ///               .background(Color.white)
    ///               .cornerRadius(8)
    ///               .shadow(radius: 10)
    ///       }
    ///   }
    ///   ```
    ///
    /// - Note: The `dismissDelay` parameter allows you to control how long the dialog stays visible. Use `.persistent`
    ///   if you want the dialog to remain visible until the user dismisses it manually.
    func peekDialog<Content: View>(
        isPresented: Binding<Bool>,
        dismissDelay: PeekDialogDelay = .persistent,
        placement: VerticalAlignment = .top,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(
            PeekDialog(
                isPresented: isPresented,
                selfDismissDelay: dismissDelay,
                placement: placement,
                content: content
            )
        )
    }
    
    /// Displays a peek dialog with customizable content and dismissal behavior, tied to an optional item.
    ///
    /// This function attaches a `PeekDialog` modifier to a view, allowing you to present a dialog that is
    /// triggered by the presence of an optional item. The dialog can automatically dismiss itself after a
    /// specified delay or remain visible until explicitly dismissed.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional item. When the item is non-`nil`, the dialog is presented.
    ///     When the item becomes `nil`, the dialog is dismissed.
    ///   - dismissDelay: The duration for which the dialog should remain visible before automatically dismissing.
    ///     Defaults to `.persistent`, meaning the dialog will stay visible until manually dismissed.
    ///   - placement: The vertical alignment of the dialog. Use `.top`, `.center`, or `.bottom`. Defaults to `.top`.
    ///   - content: The content to display inside the dialog.
    ///
    /// ## Example:
    ///   ```swift
    ///   @State private var myString: String? = nil
    ///
    ///   var body: some View {
    ///       Button("Show Dialog with Item") {
    ///           activeItem = "Example Item"
    ///       }
    ///       .peekDialog(with: $myString, dismissDelay: .medium) { item in
    ///               Text("Dialog for item: \(item)")
    ///                   .padding()
    ///                   .background(Color.white)
    ///                   .cornerRadius(8)
    ///                   .shadow(radius: 10)
    ///           }
    ///   }
    ///   ```
    ///
    /// - Note: The `dismissDelay` parameter allows you to control how long the dialog stays visible.
    /// Use `.persistent` if you want the dialog to remain visible until the user dismisses it manually
    /// or the item becomes `nil`.
    func peekDialog<T, Content: View>(
        with item: Binding<T?>,
        dismissDelay: PeekDialogDelay = .persistent,
        placement: VerticalAlignment = .top,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (T) -> Content
    ) -> some View {
        modifier(
            PeekDialog(
                item: item,
                selfDismissDelay: dismissDelay,
                placement: placement,
                onDismiss: onDismiss,
                content: content
            )
        )
    }
    
    /// Applies a custom style to a peek dialog.
    ///
    /// Use this modifier to customize the appearance of a peek dialog by providing a type that conforms to `DialogStyle`.
    /// The style will be applied to the dialog when it is presented.
    ///
    /// - Parameter style: A type conforming to `DialogStyle` that defines the visual appearance of the dialog.
    ///
    /// ## Example:
    /// ```swift
    /// @State private var showDialog = false
    ///
    /// var body: some View {
    ///     Button("Show Dialog") {
    ///         showDialog = true
    ///     }
    ///     .peekDialog(isPresented: $showDialog) {
    ///         VStack {
    ///             Text("Custom styled dialog")
    ///                 .padding()
    ///         }
    ///         .dialogStyle(.glassRegular) // Apply glass effect style
    ///     }
    /// }
    /// ```
    ///
    /// ## Creating Custom Styles:
    /// You can create your own dialog styles by conforming to the `DialogStyle` protocol:
    ///
    /// ```swift
    /// struct CustomDialogStyle: DialogStyle {
    ///     func makeBody(configuration: Configuration) -> some View {
    ///         configuration.passedContent
    ///             .background(Color.blue.opacity(0.8))
    ///             .cornerRadius(16)
    ///     }
    /// }
    ///
    /// extension DialogStyle where Self == CustomDialogStyle {
    ///     static var custom: Self { CustomDialogStyle() }
    /// }
    /// ```
    ///
    /// - Note: The dialog style must be applied to the content **inside** the `peekDialog` closure, not on the view that has the `peekDialog` modifier.
    ///
    /// - SeeAlso: `DialogStyle`, `PeekDialog`
    func dialogStyle<S: DialogStyle>(_ style: S) -> some View {
        preference(key: PeekDialogStylePreferenceKey.self,
                   value: AnyDialogStyle(style))
    }
}
