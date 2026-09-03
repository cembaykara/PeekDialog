//
//  PeekDialogPreferenceKeys.swift
//  PeekDialog
//
//  Created by Baris Cem Baykara.
//

import SwiftUI

/// Carries the `.dialogStyle` selection from the dialog content to the dialog view.
struct PeekDialogStylePreferenceKey: PreferenceKey {
	static var defaultValue: AnyDialogStyle = .default

	static func reduce(value: inout AnyDialogStyle, nextValue: () -> AnyDialogStyle) {
		value = nextValue()
	}
}

/// Carries `.peekInteractiveDismissDisabled` from the dialog content to the dialog view.
struct PeekInteractiveDismissKey: PreferenceKey {
	static var defaultValue = false

	static func reduce(value: inout Bool, nextValue: () -> Bool) {
		value = nextValue()
	}
}

/// Carries `.peekPlacementInset` from the dialog content to the dialog view.
///
/// Extra distance beyond the host’s fixed edge padding (`8`). Applied with
/// `.offset` so it does not change layout size or shift siblings in a ZStack.
struct PeekPlacementInsetKey: PreferenceKey {
	static var defaultValue: CGFloat = 0

	static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
		value = nextValue()
	}
}

/// Nudges a dialog from its placement anchor without affecting layout.
struct PeekPlacementInsetModifier: ViewModifier {
	let inset: CGFloat
	let placement: VerticalAlignment

	func body(content: Content) -> some View {
		content.offset(y: offsetY)
	}

	private var offsetY: CGFloat {
		guard inset != 0 else { return 0 }
		switch placement {
		case .bottom:
			return -inset
		default:
			// `.top`, `.center`, and any other alignment: positive = away from top / down.
			return inset
		}
	}
}

#if os(iOS)
/// Reports each dialog's on-screen frame so the overlay window knows where to
/// accept touches (see `PeekWindow`).
struct PeekDialogFrameKey: PreferenceKey {
	static var defaultValue: [UUID: CGRect] = [:]

	static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
		value.merge(nextValue(), uniquingKeysWith: { $1 })
	}
}
#endif
