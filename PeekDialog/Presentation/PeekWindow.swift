//
//  PeekWindow.swift
//  PeekDialog
//
//  Created by Baris Cem Baykara.
//

#if os(iOS)
import UIKit

/// Overlay window that passes touches through to the app except where they land
/// on a dialog.
///
/// SwiftUI renders the whole overlay into a single hosting view, so UIView
/// hit-testing can't tell dialog content from empty space on its own. The
/// dialog rects (reported from SwiftUI) are the only reliable signal.
final class PeekWindow: UIWindow {
	/// Dialog frames in this window's coordinate space.
	var dialogFrames: [CGRect] = []

	override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
		let isOnDialog = dialogFrames.contains { $0.insetBy(dx: -12, dy: -12).contains(point) }
		guard isOnDialog else { return nil }
		return super.hitTest(point, with: event)
	}
}
#endif
