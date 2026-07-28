//
//  PeekStackLayout.swift
//  PeekDialog
//
//  Created by Baris Cem Baykara.
//

#if os(iOS)
import SwiftUI

/// A single dialog resolved into concrete on-screen layout values.
struct PeekDialogArrangement: Identifiable {
	var id: UUID { state.id }
	let state: PeekDialogState
	let isFront: Bool
	let scale: CGFloat
	let opacity: Double
	let yOffset: CGFloat
	let zIndex: Double
}

/// Turns the presented dialogs at a placement into their on-screen arrangement.
///
/// This is the only place where stacked and independent dialogs diverge: an
/// independent dialog is simply always the front of a stack of one.
struct PeekStackLayout {
	var maxVisibleDialogs = 2

	func resolve(_ dialogs: [PeekDialogState], at placement: VerticalAlignment) -> [PeekDialogArrangement] {
		let atPlacement = dialogs.filter { $0.placement == placement }
		let independent = atPlacement.filter { $0.stacking == .independent }
		let stacked = atPlacement.filter { $0.stacking == .stacked }

		var result = independent.map {
			PeekDialogArrangement(state: $0, isFront: true, scale: 1, opacity: 1, yOffset: 0, zIndex: 1_000)
		}

		let visibleStart = stacked.count - min(maxVisibleDialogs, stacked.count)

		for (index, state) in stacked.enumerated() where index >= visibleStart {
			let stackPosition = stacked.count - 1 - index
			let isFront = stackPosition == 0
			result.append(
				PeekDialogArrangement(
					state: state,
					isFront: isFront,
					scale: isFront ? 1 : 0.92,
					opacity: isFront ? 1 : 0.6,
					yOffset: offset(for: stackPosition, stackOffset: state.stackOffset, placement: placement),
					zIndex: Double(1_000 - stackPosition)
				)
			)
		}

		return result
	}

	private func offset(for stackPosition: Int, stackOffset: CGFloat, placement: VerticalAlignment) -> CGFloat {
		guard stackPosition > 0 else { return 0 }
		let distance = CGFloat(stackPosition) * stackOffset
		return placement == .bottom ? -distance : distance
	}
}
#endif
