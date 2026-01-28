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

/// Manages UIWindow-level presentation of multiple peek dialogs.
@MainActor
final class PeekPresenter {
    
    static let shared = PeekPresenter()
    
    /// Maximum number of visible stacked dialogs
    private let maxVisibleDialogs = 2
    
    /// All dialog entries by ID for quick lookup
    private var dialogsByID: [UUID: DialogEntry] = [:]
    
    /// Ordered list of stacked dialog IDs (newest last) - only for stacked behavior
    private var stackedDialogOrder: [UUID] = []
    
    private init() {}
    
    // MARK: - Present
    
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
        // If this dialog ID already exists, just update content
        if let existing = dialogsByID[id] {
            existing.contentHolder.content = AnyView(content)
            return
        }
        
        // Get the active window scene
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
                ?? UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first
        else { return }
        
        // Add to stacking order if using stacked behavior
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
        
        // Create passthrough window
        let newWindow = PassthroughWindow(windowScene: scene)
        newWindow.windowLevel = .alert + 1 + CGFloat(dialogsByID.count) * 0.001
        newWindow.backgroundColor = .clear
        newWindow.isOpaque = false
        
        // Create container
        let newContainer = PeekContainer()
        
        // Create hosting controller
        let hosting = UIHostingController(rootView: wrappedView)
        hosting.view.backgroundColor = .clear
        
        // Setup view hierarchy
        let rootVC = UIViewController()
        rootVC.view.backgroundColor = .clear
        rootVC.view.isUserInteractionEnabled = true
        rootVC.view.addSubview(newContainer)
        
        // Container is sized to fit content, not full screen
        newContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Horizontal: full width with padding
        NSLayoutConstraint.activate([
            newContainer.leadingAnchor.constraint(equalTo: rootVC.view.leadingAnchor, constant: 16),
            newContainer.trailingAnchor.constraint(equalTo: rootVC.view.trailingAnchor, constant: -16)
        ])
        
        // Vertical: position based on placement
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
        
        // Hosting view fills container (which is content-sized)
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: newContainer.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: newContainer.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: newContainer.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: newContainer.bottomAnchor)
        ])
        hosting.didMove(toParent: rootVC)
        
        newWindow.rootViewController = rootVC
        
        // Store the dialog entry
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
        
        // For independent dialogs, just show them immediately
        if stacking == .independent {
            holder.isFront = true
            newWindow.makeKeyAndVisible()
            return
        }
        
        // Update visibility of all stacked dialogs at this placement
        updateVisibility(for: placement)
    }
    
    // MARK: - Dismiss
    
    func dismiss(id: UUID) {
        guard let entry = dialogsByID[id] else { return }
        
        let window = entry.window
        let placement = entry.placement
        let stacking = entry.stacking
        
        UIView.animate(withDuration: 0.2, animations: {
            window.alpha = 0
        }, completion: { [weak self] _ in
            guard let self = self else { return }
            // Only cleanup if this dialog is still tracked
            if self.dialogsByID[id] != nil {
                self.cleanupDialog(id: id)
                // Show next dialog in queue after cleanup (only for stacked)
                if stacking == .stacked {
                    self.updateVisibility(for: placement)
                }
            }
        })
    }
    
    /// Dismiss all active dialogs
    func dismissAll() {
        for id in dialogsByID.keys {
            dismiss(id: id)
        }
    }
    
    private func cleanupDialog(id: UUID) {
        guard let entry = dialogsByID.removeValue(forKey: id) else { return }
        stackedDialogOrder.removeAll { $0 == id }
        entry.window.isHidden = true
        entry.window.rootViewController = nil
    }
    
    // MARK: - Visibility Management
    
    /// Updates visibility of dialogs at a given placement.
    /// Only the newest `maxVisibleDialogs` are visible, others are hidden.
    private func updateVisibility(for placement: VerticalAlignment) {
        // Get stacked dialogs at this placement in order (oldest to newest)
        let dialogsAtPlacement = stackedDialogOrder.compactMap { id -> DialogEntry? in
            guard let entry = dialogsByID[id], 
                  entry.placement == placement,
                  entry.stacking == .stacked else { return nil }
            return entry
        }
        
        // Determine which should be visible (newest ones)
        let visibleCount = min(maxVisibleDialogs, dialogsAtPlacement.count)
        let visibleStartIndex = dialogsAtPlacement.count - visibleCount
        
        for (index, entry) in dialogsAtPlacement.enumerated() {
            let shouldBeVisible = index >= visibleStartIndex
            // 0 = front (newest visible), 1 = behind, etc.
            let stackPosition = shouldBeVisible ? (dialogsAtPlacement.count - 1 - index) : 0
            let isFront = shouldBeVisible && stackPosition == 0
            
            // Update front status (controls timer in SwiftUI)
            entry.contentHolder.isFront = isFront
            
            // Calculate target transform
            let scale: CGFloat = isFront ? 1.0 : 0.92
            var targetTransform = CGAffineTransform(scaleX: scale, y: scale)
            
            if shouldBeVisible && !isFront {
                let yOffset: CGFloat
                switch placement {
                case .top:
                    yOffset = CGFloat(stackPosition) * entry.stackOffset // Push down
                case .bottom:
                    yOffset = CGFloat(stackPosition) * -entry.stackOffset // Push up
                default:
                    yOffset = CGFloat(stackPosition) * entry.stackOffset // Center: push down
                }
                targetTransform = targetTransform.translatedBy(x: 0, y: yOffset)
            }
            
            // If transitioning from hidden to visible, set initial state first
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
                    // Reset transform when hiding
                    entry.container.transform = .identity
                }
            } completion: { _ in
                if !shouldBeVisible {
                    entry.window.isHidden = true
                }
            }
            
            // Update window level (newest on top)
            entry.window.windowLevel = .alert + 1 + CGFloat(index) * 0.001
        }
    }
    
}

// MARK: - Dialog Entry

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

// MARK: - Content Holder

private final class ContentHolder: ObservableObject {
    @Published var content: AnyView
    @Published var isFront: Bool = false
    
    init(content: AnyView) {
        self.content = content
    }
}

// MARK: - Passthrough Window

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

// MARK: - Presented Content View

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
            .offset(y: offset.height) // stackOffset handled by UIKit constraints
            .opacity(opacity)
            .gesture(dragGesture)
            .onAppear {
                withAnimation(.easeOut(duration: 0.25)) {
                    opacity = 1.0
                }
                // Start timer only if front and delay > 0
                if contentHolder.isFront && delay > 0 {
                    setTimer()
                }
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
            }
            .onChange(of: contentHolder.isFront) { isFront in
                if isFront && delay > 0 {
                    // Became front - start timer
                    setTimer()
                } else {
                    // No longer front - cancel timer
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
                    // Only restart timer if front and delay > 0
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
