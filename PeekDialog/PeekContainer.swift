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
        // Container now only covers content area, so any hit should go to content
        return super.hitTest(point, with: event)
    }
}
#endif
