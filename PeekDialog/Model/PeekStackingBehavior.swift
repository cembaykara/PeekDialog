//
//  PeekStackingBehavior.swift
//  PeekDialog
//
//  Created by Baris Cem Baykara.
//

#if os(iOS)
import Foundation

/// Determines how a dialog coexists with other dialogs at the same placement.
public enum PeekStackingBehavior {
	/// Displays on its own, unaffected by other dialogs.
	case independent
	/// Participates in the stacking queue with other stacked dialogs.
	case stacked
}
#endif
