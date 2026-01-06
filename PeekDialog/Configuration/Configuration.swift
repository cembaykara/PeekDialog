//
//  Configuration.swift
//  PeekDialog
//
//  Created by Baris Cem Baykara on 24.11.2025.
//

import SwiftUI

public protocol DialogStyle {
	associatedtype Body: View
	func makeBody(configuration: Configuration) -> Body
	
	typealias Configuration = DialogStyleConfiguration
}

public struct DialogStyleConfiguration {
	var isPresented: Bool
	var passedContent: AnyView
	var onDismiss: (() -> Void)?
}

struct AnyDialogStyle: DialogStyle {
	private let _makeBody: (Configuration) -> AnyView
	private let _id: ObjectIdentifier
	
	init<S: DialogStyle>(_ style: S) {
		self._makeBody = { AnyView(style.makeBody(configuration: $0)) }
		self._id = ObjectIdentifier(S.self)
	}
	
	func makeBody(configuration: Configuration) -> some View {
		_makeBody(configuration)
	}
	
	static var `default`: AnyDialogStyle { AnyDialogStyle(DefaultDialogStyle()) }
}

extension AnyDialogStyle: Equatable {
	static func == (lhs: AnyDialogStyle, rhs: AnyDialogStyle) -> Bool {
		lhs._id == rhs._id
	}
}

struct DefaultDialogStyle: DialogStyle {
	func makeBody(configuration: Configuration) -> some View {
		configuration.passedContent
			.frame(maxWidth: 450, minHeight: 64)
			.background {
				RoundedRectangle(cornerRadius: 24)
					.foregroundStyle(.regularMaterial)
			}
	}
}

@available(iOS 26.0, *)
public struct GlassDialogStyle: DialogStyle {
	let glassEffect: Glass
	
	public func makeBody(configuration: Configuration) -> some View {
		configuration.passedContent
			.frame(maxWidth: 450, minHeight: 64)
			.glassEffect(glassEffect.interactive(), in: .rect(cornerRadius: 30))
			.background { Rectangle().opacity(0.01) } // Workaround
	}
}

@available(iOS 26.0, *)
public extension DialogStyle where Self == GlassDialogStyle {
	
	static var glassRegular: Self { GlassDialogStyle(glassEffect: .regular) }
	
	static var glassClear: Self { GlassDialogStyle(glassEffect: .clear) }
}

struct PeekDialogStylePreferenceKey: PreferenceKey {
	static var defaultValue: AnyDialogStyle = .default
	
	static func reduce(value: inout AnyDialogStyle, nextValue: () -> AnyDialogStyle) {
		value = nextValue()
	}
}
