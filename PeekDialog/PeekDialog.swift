// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI

struct PeekDialog<PassedContent: View>: ViewModifier {
	
	typealias Style = ButtonStyle
	
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	
	@ViewBuilder private var passedContnet: PassedContent
	
	@Binding private var isPresented: Bool
	
	@State private var offset: CGSize = .zero
	@State private var opacity: Double = 1.0
	@State private var timer: Timer?
	
	private var delay: Double = 0
	private let transition = AnyTransition.asymmetric(
		insertion: .move(edge: .top),
		removal: .opacity)
	
	init<T>(
		item: Binding<T?>,
		selfDismissDelay: PeekDialogDelay = .persistent,
		@ViewBuilder content: () -> PassedContent) {
			
			self.passedContnet = content()
			self.delay = selfDismissDelay.duration
			
			self._isPresented = Binding<Bool>(
				get: { item.wrappedValue != nil },
				set: { _ in item.wrappedValue = nil })
		}
	
	init(
		isPresented: Binding<Bool>,
		selfDismissDelay: PeekDialogDelay = .persistent,
		@ViewBuilder content: () -> PassedContent) {
			
			self._isPresented = isPresented
			self.passedContnet = content()
			
			self.delay = selfDismissDelay.duration
		}
	
	func body(content: Content) -> some View {
		ZStack {
			content
			if isPresented {
				VStack {
					VStack {
						passedContnet
					}
					.background {
						RoundedRectangle(cornerRadius: 24)
							.foregroundStyle(.regularMaterial)
					}
					.shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 10)
					.frame(
						maxWidth: horizontalSizeClass == .regular ? 420 : .infinity)
					
					Spacer()
				}
				.padding([.horizontal, .bottom])
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
								offset = CGSize(width: 0, height: gesture.translation.height)
								dismiss()
							} else {
								withAnimation(.interactiveSpring()) {
									offset = .zero
								}
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

#Preview {
	
	struct PreviewableDialog: View {
		@State var item: Int? = 1
		var mode: Int = 1
		
		var body: some View {
			VStack {
				Button("Show banner") { withAnimation { item = mode } }
			}
			.peekDialog(with: $item) {
				HStack(alignment: .firstTextBaseline) {
					Image(systemName: "film.fill")
						.foregroundColor(Color.yellow)
						.padding()
					
					Text("Something")
						.padding()
					
					
					Spacer()
				}
			}
		}
	}
	
	return PreviewableDialog()
}
