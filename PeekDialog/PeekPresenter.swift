//
//  PeekPresenter.swift
//  PeekDialog
//
//  Created by Baris Cem Baykara.
//

#if os(iOS)
import UIKit
import SwiftUI

@MainActor
final class PeekPresenter {
    
    static let shared = PeekPresenter()
    
    private var window: PassthroughWindow?
    private var hostingController: UIHostingController<AnyView>?
    private var container: PeekContainer?
    private var contentHolder: ContentHolder?
    
    private init() {}
    
    // MARK: - Present
    
    func present<Content: View>(
        content: Content,
        placement: VerticalAlignment,
        delay: Double,
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)?
    ) {
        if let holder = contentHolder, window != nil {
            holder.content = AnyView(content)
            return
        }
        
        cleanupWindow()
        
        // Get the active window scene
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
                ?? UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first
        else { return }
        
        let holder = ContentHolder(content: AnyView(content))
        self.contentHolder = holder
        
        let presentedView = PresentedContentView(
            contentHolder: holder,
            placement: placement,
            delay: delay,
            isPresented: isPresented,
            onDismiss: onDismiss,
            requestDismiss: { [weak self] in self?.dismiss() }
        )
        
        let wrappedView = AnyView(presentedView)
        
        let newWindow = PassthroughWindow(windowScene: scene)
        newWindow.windowLevel = .alert + 1
        newWindow.backgroundColor = .clear
        newWindow.isOpaque = false
        
        let newContainer = PeekContainer()
        
        let hosting = UIHostingController(rootView: wrappedView)
        hosting.view.backgroundColor = .clear
        
        let rootVC = UIViewController()
        rootVC.view.backgroundColor = .clear
        rootVC.view.addSubview(newContainer)
        
        newContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            newContainer.topAnchor.constraint(equalTo: rootVC.view.topAnchor),
            newContainer.leadingAnchor.constraint(equalTo: rootVC.view.leadingAnchor),
            newContainer.trailingAnchor.constraint(equalTo: rootVC.view.trailingAnchor),
            newContainer.bottomAnchor.constraint(equalTo: rootVC.view.bottomAnchor)
        ])
        
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
        newWindow.makeKeyAndVisible()
        
        self.window = newWindow
        self.hostingController = hosting
        self.container = newContainer
    }
    
    // MARK: - Dismiss
    
    func dismiss() {
        guard let w = window else { return }
        
        UIView.animate(withDuration: 0.2, animations: {
            w.alpha = 0
        }, completion: { [weak self] _ in
            guard let self = self, self.window === w else { return }
            self.cleanupWindow()
        })
    }
    
    private func cleanupWindow() {
        window?.isHidden = true
        window?.rootViewController = nil
        window = nil
        hostingController = nil
        container = nil
        contentHolder = nil
    }
}

private final class ContentHolder: ObservableObject {
    @Published var content: AnyView
    
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
        VStack(spacing: 0) {
            if placement == .bottom || placement == .center {
                Spacer(minLength: 0)
            }
            
            contentHolder.content
                .offset(y: offset.height)
                .opacity(opacity)
                .simultaneousGesture(dragGesture)
            
            if placement == .top || placement == .center {
                Spacer(minLength: 0)
            }
        }
        .padding()
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) {
                opacity = 1.0
            }
            if delay > 0 {
                setTimer()
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
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
                    if delay > 0 {
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
