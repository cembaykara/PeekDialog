//
//  PeekDialogItemView.swift
//  PeekDialog
//
//  Created by Baris Cem Baykara.
//

#if os(iOS)
import SwiftUI

/// One presented dialog: wraps the user's content with the style, shadow,
/// swipe-to-dismiss gesture and auto-dismiss timer.
struct PeekDialogItemView: View {
	@ObservedObject var state: PeekDialogState
	let isFront: Bool
	let requestDismiss: () -> Void

	@State private var style: AnyDialogStyle = .default
	@State private var offset: CGSize = .zero
	@State private var opacity: Double = 0
	@State private var timer: Timer?
	@State private var isDragging = false
	@State private var dismissDisabled = false
	@State private var placementInset: CGFloat = 0

	var body: some View {
		styledContent
			.fixedSize(horizontal: false, vertical: true)
			.contentShape(Rectangle())
			.shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 10)
			.modifier(PeekPlacementInsetModifier(
				inset: placementInset,
				placement: state.placement
			))
			.background(frameReporter)
			.offset(y: offset.height)
			.opacity(opacity)
			.overlay {
				if isDragging {
					Color.clear.contentShape(Rectangle())
				}
			}
			// `.subviews` keeps content gestures (buttons) working while disabling drag.
			.highPriorityGesture(dragGesture, including: dismissDisabled ? .subviews : .all)
			.onAppear {
				withAnimation(.easeOut(duration: 0.25)) { opacity = 1.0 }
				if isFront && state.delay > 0 { setTimer() }
			}
			.onDisappear {
				timer?.invalidate()
				timer = nil
				isDragging = false
			}
			.onChange(of: isFront) { front in
				if front && state.delay > 0 {
					setTimer()
				} else {
					timer?.invalidate()
					timer = nil
				}
			}
	}

	private var styledContent: some View {
		style.makeBody(configuration: .init(
			isPresented: true,
			passedContent: AnyView(
				state.content
					.onPreferenceChange(PeekDialogStylePreferenceKey.self) { newStyle in
						if newStyle != style { style = newStyle }
					}
					.onPreferenceChange(PeekInteractiveDismissKey.self) { disabled in
						dismissDisabled = disabled
					}
					.onPreferenceChange(PeekPlacementInsetKey.self) { inset in
						placementInset = inset
					}
			),
			onDismiss: state.onDismiss
		))
	}

	private var frameReporter: some View {
		GeometryReader { geo in
			Color.clear.preference(
				key: PeekDialogFrameKey.self,
				value: [state.id: geo.frame(in: .global)]
			)
		}
	}

	private var dragGesture: some Gesture {
		DragGesture(minimumDistance: 8)
			.onChanged { gesture in
				timer?.invalidate()
				timer = nil
				isDragging = true
				offset = CGSize(width: 0, height: gesture.translation.height)
			}
			.onEnded { gesture in
				let dismissThreshold: CGFloat = 50
				if abs(gesture.translation.height) > dismissThreshold {
					performDismiss()
				} else {
					withAnimation(.interactiveSpring()) { offset = .zero }
					if isFront && state.delay > 0 { setTimer() }
				}
				// Defer so the cancelled touch end can't land on a Button.
				DispatchQueue.main.async { isDragging = false }
			}
	}

	private func setTimer() {
		timer?.invalidate()
		timer = Timer.scheduledTimer(withTimeInterval: state.delay, repeats: false) { _ in
			Task { @MainActor in performDismiss() }
		}
	}

	private func performDismiss() {
		withAnimation(.easeIn(duration: 0.2)) { opacity = 0 }

		DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
			timer?.invalidate()
			timer = nil
			offset = .zero
			state.setPresented(false)
			state.onDismiss?()
			requestDismiss()
		}
	}
}
#endif
