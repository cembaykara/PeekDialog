//
//  PeekDialogBridge.swift
//  PeekDialog
//
//  Created by Baris Cem Baykara.
//

#if os(iOS)
import SwiftUI

/// Bridges a host view's presentation state into the presenter.
///
/// Mutations are applied on the next main-queue turn so we never publish
/// presenter state during a SwiftUI view update / `updateUIView` cycle.
struct PeekDialogBridge: UIViewRepresentable {
	let id: UUID
	let isPresented: Bool
	let content: AnyView
	let placement: VerticalAlignment
	let delay: Double
	let stacking: PeekStackingBehavior
	let stackOffset: CGFloat
	var isPresentedBinding: Binding<Bool>
	let onDismiss: (() -> Void)?

	func makeCoordinator() -> Coordinator {
		Coordinator(id: id)
	}

	func makeUIView(context: Context) -> UIView {
		let view = UIView(frame: .zero)
		view.isUserInteractionEnabled = false
		view.isHidden = true
		context.coordinator.id = id
		return view
	}

	func updateUIView(_ uiView: UIView, context: Context) {
		context.coordinator.id = id

		let id = id
		let isPresented = isPresented
		let content = content
		let placement = placement
		let delay = delay
		let stacking = stacking
		let stackOffset = stackOffset
		let binding = isPresentedBinding
		let dismissHandler = onDismiss

		// Coalesce multiple updates within the same run-loop turn.
		context.coordinator.generation += 1
		let generation = context.coordinator.generation

		DispatchQueue.main.async {
			guard context.coordinator.generation == generation else { return }

			let presenter = PeekPresenter.shared
			if isPresented {
				presenter.upsert(
					PeekDialogState(
						id: id,
						content: content,
						placement: placement,
						delay: delay,
						stacking: stacking,
						stackOffset: stackOffset,
						setPresented: { binding.wrappedValue = $0 },
						onDismiss: dismissHandler
					)
				)
			} else {
				presenter.dismiss(id: id)
			}
		}
	}

	static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
		let id = coordinator.id
		DispatchQueue.main.async {
			PeekPresenter.shared.dismiss(id: id)
		}
	}

	final class Coordinator {
		var id: UUID
		var generation = 0
		init(id: UUID) { self.id = id }
	}
}
#endif
