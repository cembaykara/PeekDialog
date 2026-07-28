//
//  PeekPresenter.swift
//  PeekDialog
//
//  Created by Baris Cem Baykara.
//

#if os(iOS)
import UIKit
import SwiftUI

/// Owns the overlay window and the list of currently presented dialogs.
@MainActor
final class PeekPresenter: ObservableObject {

	static let shared = PeekPresenter()

	/// Changes only on present / dismiss — never on live content updates.
	@Published private(set) var dialogs: [PeekDialogState] = []

	private var window: PeekWindow?

	private init() {}

	/// Inserts a new dialog or updates an existing one's content in place.
	///
	/// Must not be called synchronously from a SwiftUI view update; the bridge
	/// defers it to the next run-loop turn to avoid publishing mid-update.
	func upsert(
		id: UUID,
		content: AnyView,
		placement: VerticalAlignment,
		delay: Double,
		stacking: PeekStackingBehavior,
		stackOffset: CGFloat,
		setPresented: @escaping (Bool) -> Void,
		onDismiss: (() -> Void)?
	) {
		ensureWindow()

		if let existing = dialogs.first(where: { $0.id == id }) {
			existing.update(content: content, setPresented: setPresented, onDismiss: onDismiss)
			return
		}

		dialogs.append(
			PeekDialogState(
				id: id,
				content: content,
				placement: placement,
				delay: delay,
				stacking: stacking,
				stackOffset: stackOffset,
				setPresented: setPresented,
				onDismiss: onDismiss
			)
		)
	}

	func dismiss(id: UUID) {
		guard dialogs.contains(where: { $0.id == id }) else { return }
		dialogs.removeAll { $0.id == id }
		if dialogs.isEmpty {
			tearDownWindow()
		}
	}

	func dismissAll() {
		dialogs.removeAll()
		tearDownWindow()
	}

	/// Updates the window's touch-accepting regions from SwiftUI-reported frames.
	/// Frames arrive in screen space and are converted into the window.
	func updateHitRegions(_ globalFrames: [CGRect]) {
		guard let window else { return }
		window.dialogFrames = globalFrames.map { window.convert($0, from: nil) }
	}

	private func ensureWindow() {
		guard window == nil else { return }

		guard let scene = UIApplication.shared.connectedScenes
			.compactMap({ $0 as? UIWindowScene })
			.first(where: { $0.activationState == .foregroundActive })
			?? UIApplication.shared.connectedScenes
			.compactMap({ $0 as? UIWindowScene })
			.first
		else { return }

		let hosting = UIHostingController(rootView: PeekDialogHostView(presenter: self))
		hosting.view.backgroundColor = .clear
		hosting.view.isOpaque = false

		let newWindow = PeekWindow(windowScene: scene)
		newWindow.windowLevel = .alert + 1
		newWindow.backgroundColor = .clear
		newWindow.isOpaque = false
		newWindow.rootViewController = hosting
		newWindow.makeKeyAndVisible()

		window = newWindow
	}

	private func tearDownWindow() {
		window?.isHidden = true
		window?.rootViewController = nil
		window = nil
	}
}
#endif
