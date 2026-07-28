//
//  PeekDialogState.swift
//  PeekDialog
//
//  Created by Baris Cem Baykara.
//

#if os(iOS)
import SwiftUI

/// The live state of a single presented dialog.
///
/// A reference type so content updates repaint only this dialog rather than the
/// presenter's whole entry list, which would reset gestures and animations.
final class PeekDialogState: ObservableObject, Identifiable {
	let id: UUID
	@Published var content: AnyView
	let placement: VerticalAlignment
	let delay: Double
	let stacking: PeekStackingBehavior
	let stackOffset: CGFloat
	var setPresented: (Bool) -> Void
	var onDismiss: (() -> Void)?

	init(
		id: UUID,
		content: AnyView,
		placement: VerticalAlignment,
		delay: Double,
		stacking: PeekStackingBehavior,
		stackOffset: CGFloat,
		setPresented: @escaping (Bool) -> Void,
		onDismiss: (() -> Void)?
	) {
		self.id = id
		self.content = content
		self.placement = placement
		self.delay = delay
		self.stacking = stacking
		self.stackOffset = stackOffset
		self.setPresented = setPresented
		self.onDismiss = onDismiss
	}

	func update(
		content: AnyView,
		setPresented: @escaping (Bool) -> Void,
		onDismiss: (() -> Void)?
	) {
		self.setPresented = setPresented
		self.onDismiss = onDismiss
		self.content = content
	}
}
#endif
