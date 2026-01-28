//
//  PeekContainer.swift
//  PeekDialog
//
//  Created by Baris Cem Baykara.
//

#if os(iOS)
import UIKit

final class PeekContainer: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        isOpaque = false
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hit = super.hitTest(point, with: event)

        if hit === self {
            return nil
        }
        return hit
    }
}
#endif
