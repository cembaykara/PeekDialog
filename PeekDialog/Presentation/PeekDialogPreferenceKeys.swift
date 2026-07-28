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
