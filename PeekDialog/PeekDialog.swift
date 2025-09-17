//
//  PeekDialog.swift
//  PeekDialog
//
//  Created by Baris Cem Baykara.
//
import SwiftUI

struct PeekDialog<PassedContent: View>: ViewModifier {
	
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	
	@ViewBuilder private var passedContnet: PassedContent
	
	@Binding private var isPresented: Bool
	
	@State private var offset: CGSize = .zero
	@State private var opacity: Double = 1.0
	@State private var timer: Timer?
	
	private let onDismiss: (() -> Void)?
	private var delay: Double = 0
	private let transition = AnyTransition.asymmetric(
		insertion: .move(edge: .top),
		removal: .opacity)
	
	init<T>(
		item: Binding<T?>,
		selfDismissDelay: PeekDialogDelay = .persistent,
		onDismiss: (() -> Void)? = nil,
		@ViewBuilder content: () -> PassedContent) {
			
			self.passedContnet = content()
			self.delay = selfDismissDelay.duration
			self.onDismiss = onDismiss
			
			self._isPresented = Binding<Bool>(
				get: { item.wrappedValue != nil },
				set: { _ in item.wrappedValue = nil })
		}
	
	init(
		isPresented: Binding<Bool>,
		selfDismissDelay: PeekDialogDelay = .persistent,
		onDismiss: (() -> Void)? = nil,
		@ViewBuilder content: () -> PassedContent) {
			
			self._isPresented = isPresented
			self.passedContnet = content()
			self.onDismiss = onDismiss
			self.delay = selfDismissDelay.duration
		}
	
	func body(content: Content) -> some View {
		ZStack {
			content
			if isPresented {
				VStack {
					VStack {
						if #available(iOS 26.0, watchOS 26.0, tvOS 26.0, macOS 26.0, visionOS 26.0, *) {
							passedContnet
								.glassEffect(.clear.interactive(), in: .rect(cornerRadius: 30))
								.background { Rectangle().opacity(0.01) } // Workaround
								
						} else {
							passedContnet
								.background {
									RoundedRectangle(cornerRadius: 24)
										.foregroundStyle(.regularMaterial)
								}
						}
					}
					.shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 10)
					.frame(maxWidth: horizontalSizeClass == .regular ? 420 : .infinity)
					
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
				Rectangle()
					.fill(
						LinearGradient(
							gradient: Gradient(colors: [
								Color.blue.opacity(0.8),
								Color.purple.opacity(0.8),
								Color.indigo.opacity(0.8)
							]),
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
					.overlay(
						Image(systemName: "person.crop.circle.fill")
							.resizable()
							.scaledToFit()
							.foregroundStyle(
								LinearGradient(
									colors: [.white.opacity(0.9), .white.opacity(0.3)],
									startPoint: .top,
									endPoint: .bottom
								)
							)
							.frame(width: 80, height: 80)
							.shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
							.padding()
					)
					.frame(height: 360)
					.shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 5)
					.ignoresSafeArea(.all)
				
				Spacer()
				
				Button("Show banner") { withAnimation { item = mode } }
				
				Spacer()
			}
			.peekDialog(with: $item,
						onDismiss: { print("Dismissed") }) { item in
				
				VStack {
					HStack(alignment: .firstTextBaseline) {
						Image(systemName: "info.triangle.fill")
							.foregroundColor(Color.red)
							.padding()
						
						Text("This is a long placeholder banner message.")
							.padding()
						
						Spacer()
					}
				}
			}
		}
	}
	
	return PreviewableDialog()
}
