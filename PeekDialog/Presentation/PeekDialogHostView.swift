//
//  PeekDialogHostView.swift
//  PeekDialog
//
//  Created by Baris Cem Baykara.
//

#if os(iOS)
import SwiftUI

/// The single view hosted in the overlay window; arranges every presented dialog.
struct PeekDialogHostView: View {
	@ObservedObject var presenter: PeekPresenter

	private let layout = PeekStackLayout()

	var body: some View {
		ZStack {
			placementColumn(for: .top, alignment: .top)
			placementColumn(for: .center, alignment: .center)
			placementColumn(for: .bottom, alignment: .bottom)
		}
		.padding(.horizontal, 16)
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.onPreferenceChange(PeekDialogFrameKey.self) { frames in
			presenter.updateHitRegions(Array(frames.values))
		}
	}

	@ViewBuilder
	private func placementColumn(for placement: VerticalAlignment, alignment: Alignment) -> some View {
		let arrangements = layout.resolve(presenter.dialogs, at: placement)

		if !arrangements.isEmpty {
			VStack(spacing: 0) {
				if alignment != .top {
					Spacer(minLength: 0).allowsHitTesting(false)
				}

				ZStack {
					ForEach(arrangements) { arrangement in
						PeekDialogItemView(
							state: arrangement.state,
							isFront: arrangement.isFront,
							requestDismiss: { presenter.dismiss(id: arrangement.state.id) }
						)
						.scaleEffect(arrangement.scale)
						.opacity(arrangement.opacity)
						.offset(y: arrangement.yOffset)
						.zIndex(arrangement.zIndex)
						.animation(.easeInOut(duration: 0.25), value: arrangement.yOffset)
						.animation(.easeInOut(duration: 0.25), value: arrangement.isFront)
					}
				}
				.fixedSize(horizontal: false, vertical: true)
				.padding(.top, placement == .top ? 8 : 0)
				.padding(.bottom, placement == .bottom ? 8 : 0)

				if alignment != .bottom {
					Spacer(minLength: 0).allowsHitTesting(false)
				}
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
		}
	}
}
#endif
