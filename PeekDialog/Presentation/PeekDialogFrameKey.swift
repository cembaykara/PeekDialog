//
//  PeekDialogFrameKey.swift
//  PeekDialog
//
//  Created by Baris Cem Baykara.
//

#if os(iOS)
import SwiftUI

/// Reports each dialog's on-screen frame so the overlay window knows where to
/// accept touches (see `PeekWindow`).
struct PeekDialogFrameKey: PreferenceKey {
	static var defaultValue: [UUID: CGRect] = [:]

	static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
		value.merge(nextValue(), uniquingKeysWith: { $1 })
	}
}
#endif
