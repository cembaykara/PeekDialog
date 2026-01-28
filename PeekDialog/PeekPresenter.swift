//
//  PeekPresenter.swift
//  PeekDialog
//
//  Created by Baris Cem Baykara.
//

#if os(iOS)
import UIKit
import SwiftUI

/// Stacking behavior for peek dialogs
public enum PeekStackingBehavior {
    /// Independent - displays without affecting other notifications
    case independent
    /// Stacked - participates in the stacking queue with other stacked notifications
    case stacked
}

@MainActor
final class PeekPresenter {
    
    static let shared = PeekPresenter()
    
    private let maxVisibleDialogs = 2
    
    private var dialogsByID: [UUID: DialogEntry] = [:]
    
    private var stackedDialogOrder: [UUID] = []
    
    private init() {}
    
    func present<Content: View>(
        id: UUID,
        content: Content,
        placement: VerticalAlignment,
        delay: Double,
        stacking: PeekStackingBehavior = .independent,
        stackOffset: CGFloat = 12,
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)?
    ) {
        if let existing = dialogsByID[id] {
            existing.contentHolder.content = AnyView(content)
            return
        }
        
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
                ?? UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first
        else { return }
        
        if stacking == .stacked {
            stackedDialogOrder.append(id)
        }
        
        let holder = ContentHolder(content: AnyView(content))
        
        let presentedView = PresentedContentView(
            contentHolder: holder,
            placement: placement,
            delay: delay,
            isPresented: isPresented,
            onDismiss: onDismiss,
            requestDismiss: { [weak self] in self?.dismiss(id: id) }
        )
        
        let wrappedView = AnyView(presentedView)
        
        let newWindow = PassthroughWindow(windowScene: scene)
        newWindow.windowLevel = .alert + 1 + CGFloat(dialogsByID.count) * 0.001
        newWindow.backgroundColor = .clear
        newWindow.isOpaque = false
        
        let newContainer = PeekContainer()
        
        let hosting = UIHostingController(rootView: wrappedView)
        hosting.view.backgroundColor = .clear
        
        let rootVC = UIViewController()
        rootVC.view.backgroundColor = .clear
        rootVC.view.isUserInteractionEnabled = true
        rootVC.view.addSubview(newContainer)
        
        newContainer.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            newContainer.leadingAnchor.constraint(equalTo: rootVC.view.leadingAnchor, constant: 16),
            newContainer.trailingAnchor.constraint(equalTo: rootVC.view.trailingAnchor, constant: -16)
        ])
        
        switch placement {
        case .top:
            newContainer.topAnchor.constraint(equalTo: rootVC.view.safeAreaLayoutGuide.topAnchor, constant: 8).isActive = true
        case .bottom:
            newContainer.bottomAnchor.constraint(equalTo: rootVC.view.safeAreaLayoutGuide.bottomAnchor, constant: -8).isActive = true
        default: // center
            newContainer.centerYAnchor.constraint(equalTo: rootVC.view.centerYAnchor).isActive = true
        }
        
        rootVC.addChild(hosting)
        newContainer.addSubview(hosting.view)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: newContainer.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: newContainer.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: newContainer.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: newContainer.bottomAnchor)
        ])
        hosting.didMove(toParent: rootVC)
        
        newWindow.rootViewController = rootVC
        
        let entry = DialogEntry(
            id: id,
            window: newWindow,
            hostingController: hosting,
            container: newContainer,
            contentHolder: holder,
            placement: placement,
            stacking: stacking,
            stackOffset: stackOffset
        )
        dialogsByID[id] = entry
        
        if stacking == .independent {
            holder.isFront = true
            newWindow.makeKeyAndVisible()
            return
        }
        
        updateVisibility(for: placement)
    }
    
    // MARK: - Dismiss
    
    func dismiss(id: UUID) {
        guard let entry = dialogsByID[id] else { return }
        
        let window = entry.window
        let placement = entry.placement
        let stacking = entry.stacking
        
        cleanupDialog(id: id)
        
        if stacking == .stacked {
            updateVisibility(for: placement)
        }
        
        UIView.animate(withDuration: 0.15, animations: {
            window.alpha = 0
        }, completion: { _ in
            window.isHidden = true
            window.rootViewController = nil
        })
    }
    
    func dismissAll() {
        for id in dialogsByID.keys {
            dismiss(id: id)
        }
    }
    
    private func cleanupDialog(id: UUID) {
        dialogsByID.removeValue(forKey: id)
        stackedDialogOrder.removeAll { $0 == id }
    }
    
    private func updateVisibility(for placement: VerticalAlignment) {
        let dialogsAtPlacement = stackedDialogOrder.compactMap { id -> DialogEntry? in
            guard let entry = dialogsByID[id], 
                  entry.placement == placement,
                  entry.stacking == .stacked else { return nil }
            return entry
        }
        
        let visibleCount = min(maxVisibleDialogs, dialogsAtPlacement.count)
        let visibleStartIndex = dialogsAtPlacement.count - visibleCount
        
        for (index, entry) in dialogsAtPlacement.enumerated() {
            let shouldBeVisible = index >= visibleStartIndex
            let stackPosition = shouldBeVisible ? (dialogsAtPlacement.count - 1 - index) : 0
            let isFront = shouldBeVisible && stackPosition == 0

            entry.contentHolder.isFront = isFront

            let scale: CGFloat = isFront ? 1.0 : 0.92
            var targetTransform = CGAffineTransform(scaleX: scale, y: scale)
            
            if shouldBeVisible && !isFront {
                let yOffset: CGFloat
                switch placement {
                case .top:
                    yOffset = CGFloat(stackPosition) * entry.stackOffset
                case .bottom:
                    yOffset = CGFloat(stackPosition) * -entry.stackOffset
                default:
                    yOffset = CGFloat(stackPosition) * entry.stackOffset
                }
                targetTransform = targetTransform.translatedBy(x: 0, y: yOffset)
            }
            
            let wasHidden = entry.window.isHidden
            if wasHidden && shouldBeVisible {
                entry.window.isHidden = false
                entry.window.alpha = 0
                entry.container.transform = targetTransform
            }
            
            UIView.animate(withDuration: 0.25) {
                if shouldBeVisible {
                    entry.window.alpha = isFront ? 1.0 : 0.6
                    entry.container.transform = targetTransform
                } else {
                    entry.window.alpha = 0
                    entry.container.transform = .identity
                }
            } completion: { _ in
                if !shouldBeVisible {
                    entry.window.isHidden = true
                }
            }

            entry.window.windowLevel = .alert + 1 + CGFloat(index) * 0.001
        }
    }
    
}

private final class DialogEntry {
    let id: UUID
    let window: UIWindow
    let hostingController: UIHostingController<AnyView>
    let container: PeekContainer
    let contentHolder: ContentHolder
    let placement: VerticalAlignment
    let stacking: PeekStackingBehavior
    let stackOffset: CGFloat
    
    init(id: UUID, window: UIWindow, hostingController: UIHostingController<AnyView>, container: PeekContainer, contentHolder: ContentHolder, placement: VerticalAlignment, stacking: PeekStackingBehavior, stackOffset: CGFloat) {
        self.id = id
        self.window = window
        self.hostingController = hostingController
        self.container = container
        self.contentHolder = contentHolder
        self.placement = placement
        self.stacking = stacking
        self.stackOffset = stackOffset
    }
}

private final class ContentHolder: ObservableObject {
    @Published var content: AnyView
    @Published var isFront: Bool = false
    
    init(content: AnyView) {
        self.content = content
    }
}

private final class PassthroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hit = super.hitTest(point, with: event)
        // Pass through if hit is just the root view or nil
        if hit === rootViewController?.view || hit == nil {
            return nil
        }
        return hit
    }
}

private struct PresentedContentView: View {
    @ObservedObject var contentHolder: ContentHolder
    let placement: VerticalAlignment
    let delay: Double
    let isPresented: Binding<Bool>
    let onDismiss: (() -> Void)?
    let requestDismiss: () -> Void
    
    @State private var offset: CGSize = .zero
    @State private var opacity: Double = 0
    @State private var timer: Timer?
    
    var body: some View {
        contentHolder.content
            .fixedSize(horizontal: false, vertical: true)
            .contentShape(Rectangle())
            .offset(y: offset.height)
            .opacity(opacity)
            .gesture(dragGesture)
            .onAppear {
                withAnimation(.easeOut(duration: 0.25)) {
                    opacity = 1.0
                }

                if contentHolder.isFront && delay > 0 {
                    setTimer()
                }
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
            }
            .onChange(of: contentHolder.isFront) { isFront in
                if isFront && delay > 0 { setTimer() }
				else {
                    timer?.invalidate()
                    timer = nil
                }
            }
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { gesture in
                timer?.invalidate()
                timer = nil
                offset = CGSize(width: 0, height: gesture.translation.height)
            }
            .onEnded { gesture in
                let dismissThreshold: CGFloat = 50
                if abs(gesture.translation.height) > dismissThreshold {
                    performDismiss()
                } else {
                    withAnimation(.interactiveSpring()) {
                        offset = .zero
                    }
					
                    if contentHolder.isFront && delay > 0 {
                        setTimer()
                    }
                }
            }
    }
    
    private func setTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            Task { @MainActor in
                performDismiss()
            }
        }
    }
    
    private func performDismiss() {
        withAnimation(.easeIn(duration: 0.2)) {
            opacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            timer?.invalidate()
            timer = nil
            offset = .zero
            isPresented.wrappedValue = false
            onDismiss?()
            requestDismiss()
        }
    }
}
#endif
