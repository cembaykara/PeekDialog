//
//  PeekDialog.swift
//  PeekDialog
//
//  Created by Baris Cem Baykara.
//
import SwiftUI

struct PeekDialog: ViewModifier {
	
	private let contentBuilder: () -> AnyView
	
	@Binding private var isPresented: Bool
	
	@State private var dialogID = UUID()
	
	#if !os(iOS)
	@State private var style: AnyDialogStyle = .default
	@State private var offset: CGSize = .zero
	@State private var opacity: Double = 1.0
	@State private var timer: Timer?
	@State private var dismissDisabled = false
	#endif
	
	private let delay: Double
	private let placement: VerticalAlignment
	private let onDismiss: (() -> Void)?
	
	#if os(iOS)
	private let stacking: PeekStackingBehavior
	private let stackOffset: CGFloat
	#endif
	
	#if !os(iOS)
	private var transition: AnyTransition {
		switch placement {
		case .top: .asymmetric(insertion: .move(edge: .top), removal: .opacity)
		case .bottom: .asymmetric(insertion: .move(edge: .bottom), removal: .opacity)
		default: .asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.9)), removal: .opacity)
		}
	}
	#endif
	
	#if os(iOS)
	init<T, Content: View>(
		item: Binding<T?>,
		selfDismissDelay: PeekDialogDelay = .persistent,
		placement: VerticalAlignment = .top,
		stacking: PeekStackingBehavior = .independent,
		stackOffset: CGFloat = 12,
		onDismiss: (() -> Void)? = nil,
		@ViewBuilder content: @escaping (T) -> Content
	) {
		self.delay = selfDismissDelay.duration
		self.placement = placement
		self.onDismiss = onDismiss
		self.stacking = stacking
		self.stackOffset = stackOffset
		
		self._isPresented = Binding<Bool>(
			get: { item.wrappedValue != nil },
			set: { newValue in
				if !newValue {
					item.wrappedValue = nil
				}
			}
		)
		
		self.contentBuilder = {
			if let value = item.wrappedValue {
				return AnyView(content(value))
			} else {
				return AnyView(EmptyView())
			}
		}
	}
	
	init<Content: View>(
		isPresented: Binding<Bool>,
		selfDismissDelay: PeekDialogDelay = .persistent,
		placement: VerticalAlignment = .top,
		stacking: PeekStackingBehavior = .independent,
		stackOffset: CGFloat = 12,
		onDismiss: (() -> Void)? = nil,
		@ViewBuilder content: @escaping () -> Content
	) {
		self._isPresented = isPresented
		self.placement = placement
		self.onDismiss = onDismiss
		self.delay = selfDismissDelay.duration
		self.stacking = stacking
		self.stackOffset = stackOffset
		self.contentBuilder = { AnyView(content()) }
	}
	#else
	init<T, Content: View>(
		item: Binding<T?>,
		selfDismissDelay: PeekDialogDelay = .persistent,
		placement: VerticalAlignment = .top,
		onDismiss: (() -> Void)? = nil,
		@ViewBuilder content: @escaping (T) -> Content
	) {
		self.delay = selfDismissDelay.duration
		self.placement = placement
		self.onDismiss = onDismiss
		
		self._isPresented = Binding<Bool>(
			get: { item.wrappedValue != nil },
			set: { newValue in
				if !newValue {
					item.wrappedValue = nil
				}
			}
		)
		
		self.contentBuilder = {
			if let value = item.wrappedValue {
				return AnyView(content(value))
			} else {
				return AnyView(EmptyView())
			}
		}
	}
	
	init<Content: View>(
		isPresented: Binding<Bool>,
		selfDismissDelay: PeekDialogDelay = .persistent,
		placement: VerticalAlignment = .top,
		onDismiss: (() -> Void)? = nil,
		@ViewBuilder content: @escaping () -> Content
	) {
		self._isPresented = isPresented
		self.placement = placement
		self.onDismiss = onDismiss
		self.delay = selfDismissDelay.duration
		self.contentBuilder = { AnyView(content()) }
	}
	#endif
	
	func body(content: Content) -> some View {
		#if os(iOS)
		content.background(
			PeekDialogBridge(
				id: dialogID,
				isPresented: isPresented,
				content: contentBuilder(),
				placement: placement,
				delay: delay,
				stacking: stacking,
				stackOffset: stackOffset,
				isPresentedBinding: $isPresented,
				onDismiss: onDismiss
			)
			.frame(width: 0, height: 0)
			.allowsHitTesting(false)
			.accessibilityHidden(true)
		)
		#else
		ZStack {
			content
			if isPresented {
				VStack(spacing: 0) {
					if placement == .bottom || placement == .center {
						Spacer(minLength: 0)
					}
					dialogContent
					if placement == .top || placement == .center {
						Spacer(minLength: 0)
					}
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
								dismissDialog()
							} else {
								withAnimation(.interactiveSpring()) { offset = .zero }
								if delay > 0 { setTimer() }
							}
						},
					including: dismissDisabled ? .subviews : .all
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
		#endif
	}
	
	#if !os(iOS)
	@ViewBuilder
	private var dialogContent: some View {
		VStack {
			style.makeBody(configuration: .init(
				isPresented: isPresented,
				passedContent: contentBuilder(),
				onDismiss: onDismiss
			))
		}
		.contentShape(Rectangle())
		.shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 10)
		.onPreferenceChange(PeekDialogStylePreferenceKey.self) { newStyle in
			style = newStyle
		}
		.onPreferenceChange(PeekInteractiveDismissKey.self) { disabled in
			dismissDisabled = disabled
		}
	}
	
	@MainActor
	private func dismissDialog() {
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
				dismissDialog()
			}
		}
	}
	#endif
}

// MARK: - PeekDialogDelay

/// Defines the duration for which a peek dialog remains visible before automatically dismissing.
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
	
	var duration: Double {
		switch self {
		case .short: 2.0
		case .medium: 5.0
		case .long: 8.0
		case .persistent: 0.0
		case .custom(let value): value
		}
	}
}

// MARK: - Stack modifier

#if os(iOS)

struct PeekDialogStackModifier<T: Identifiable, ItemContent: View>: ViewModifier {
	@Binding var items: [T]
	let dismissDelay: PeekDialogDelay
	let placement: VerticalAlignment
	let stackOffset: CGFloat
	let onDismiss: ((T) -> Void)?
	let content: (T) -> ItemContent
	
	func body(content: Content) -> some View {
		content
			.background(
				ForEach(items) { item in
					Color.clear
						.modifier(
							PeekDialog(
								item: itemBinding(for: item),
								selfDismissDelay: dismissDelay,
								placement: placement,
								stacking: .stacked,
								stackOffset: stackOffset,
								onDismiss: { onDismiss?(item) },
								content: { _ in self.content(item) }
							)
						)
				}
			)
	}
	
	private func itemBinding(for item: T) -> Binding<T?> {
		Binding<T?>(
			get: {
				items.first { $0.id == item.id }
			},
			set: { newValue in
				if newValue == nil {
					items.removeAll { $0.id == item.id }
				}
			}
		)
	}
}

#endif
