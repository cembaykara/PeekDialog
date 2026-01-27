//
//  PeekDialog.swift
//  PeekDialog
//
//  Created by Baris Cem Baykara.
//
import SwiftUI

struct PeekDialog<PassedContent: View>: ViewModifier {
	
	@ViewBuilder private var passedContnet: PassedContent
	
	@Binding private var isPresented: Bool
	
	@State private var offset: CGSize = .zero
	@State private var opacity: Double = 1.0
	@State private var timer: Timer?
	@State private var style: AnyDialogStyle = .default
	
	private var delay: Double = 0
	private let placement: VerticalAlignment
	private let onDismiss: (() -> Void)?
	
	private var transition: AnyTransition {
		switch placement {
		case .top: .asymmetric(insertion: .move(edge: .top), removal: .opacity)
		case .bottom: .asymmetric(insertion: .move(edge: .bottom), removal: .opacity)
		default: .asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.9)), removal: .opacity)
		}
	}
	
	init<T>(
		item: Binding<T?>,
		selfDismissDelay: PeekDialogDelay = .persistent,
		placement: VerticalAlignment = .top,
		onDismiss: (() -> Void)? = nil,
		@ViewBuilder content: () -> PassedContent) {
			
			self.passedContnet = content()
			self.delay = selfDismissDelay.duration
			self.placement = placement
			self.onDismiss = onDismiss
			
			self._isPresented = Binding<Bool>(
				get: { item.wrappedValue != nil },
				set: { _ in item.wrappedValue = nil })
		}
	
	init(
		isPresented: Binding<Bool>,
		selfDismissDelay: PeekDialogDelay = .persistent,
		placement: VerticalAlignment = .top,
		onDismiss: (() -> Void)? = nil,
		@ViewBuilder content: () -> PassedContent) {

			self._isPresented = isPresented
			self.passedContnet = content()
			self.placement = placement
			self.onDismiss = onDismiss
			self.delay = selfDismissDelay.duration
		}
	
	@ViewBuilder
	private var dialogContent: some View {
		VStack {
			style.makeBody(configuration: .init(isPresented: isPresented,
												passedContent: AnyView(passedContnet),
												onDismiss: onDismiss))
		}
		.shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 10)
		.onPreferenceChange(PeekDialogStylePreferenceKey.self) { newStyle in
			style = newStyle
		}
	}
	
	func body(content: Content) -> some View {
		ZStack {
			content
			if isPresented {
				VStack(spacing: 0) {
					if placement == .bottom
						|| placement == .center { Spacer(minLength: 0) }
					dialogContent
					if placement == .top
						|| placement == .center { Spacer(minLength: 0) }
				}
				.padding()
				.offset(y: offset.height)
				.opacity(opacity)
				.transition(transition)
				.simultaneousGesture(
					DragGesture()
						.onChanged { gesture in
							timer?.invalidate()
							timer = nil
							offset = CGSize(width: 0, height: gesture.translation.height)
						}
						.onEnded { gesture in
							let dismissThreshold: CGFloat = 50
							if abs(gesture.translation.height) > dismissThreshold {
								dismiss()
							} else {
								withAnimation(.interactiveSpring()) { offset = .zero }
								if delay > 0 { setTimer() }
							}
						}
				)
				.onAppear {
					opacity = 1.0
					if delay > 0 { setTimer() }
				}
				.onDisappear {
					timer?.invalidate()
					timer = nil
				}
			}
		}
	}
	
	@MainActor
	private func dismiss() {
		withAnimation(.easeIn(duration: 0.20)) {
			opacity = 0.0
			isPresented = false
			
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
				timer?.invalidate()
				timer = nil
				offset = .zero
				
				onDismiss?()
			}
		}
	}
	
	private func setTimer() {
		timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
			Task { @MainActor in
				dismiss()
			}
		}
	}
	
	private func setStyle(_ style: AnyDialogStyle) {
		self.style = style
	}
}

/// Defines the duration for which a peek dialog remains visible before automatically dismissing.
///
/// Use this enum to specify how long a peek dialog should stay visible.
/// It supports predefined durations as well as a custom duration for flexibility.
public enum PeekDialogDelay {
	
	/// Short duration (2 seconds).
	case short
	
	/// Medium duration (5 seconds).
	case medium
	
	/// Long duration (8 seconds).
	case long
	
	/// Will stay visible until dismissed.
	case persistent
	
	/// A custom duration in seconds.
	case custom(seconds: Double)
	
	fileprivate var duration: Double {
		switch self {
			case .short: 2.0
			case .medium: 5.0
			case .long: 8.0
			case .persistent: 0.0
			case .custom(let value): value
		}
	}
}
