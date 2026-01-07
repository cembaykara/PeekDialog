//
//  Examples.swift
//  PeekDialog
//
//  Created by Baris Cem Baykara.
//
import SwiftUI

// MARK: - Preview Examples

#Preview("PeekDialog Examples") {
	struct PeekDialogExamplesPreview: View {
		enum ExampleType: String, CaseIterable {
			case success = "Success Notification"
			case error = "Error Notification"
			case upload = "Upload Progress"
			case toast = "Toast Notification"
			
			var gradient: LinearGradient {
				switch self {
				case .success:
					return LinearGradient(
						colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					)
				case .error:
					return LinearGradient(
						colors: [.orange.opacity(0.5), .red.opacity(0.5)],
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					)
				case .upload:
					return LinearGradient(
						colors: [.green.opacity(0.5), .mint.opacity(0.5)],
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					)
				case .toast:
					return LinearGradient(
						colors: [.gray.opacity(0.7), .black.opacity(0.7)],
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					)
				}
			}
		}
		
		@State private var currentGradient: ExampleType = .success
		@State private var showSuccess = false
		@State private var errorMessage: String? = nil
		@State private var showUpload = false
		@State private var uploadCompleted = false
		@State private var showToast = false
		
		var body: some View {
			ZStack {
				// Enhanced background with overlay
				currentGradient.gradient
					.ignoresSafeArea()
					.overlay {
						Rectangle()
							.fill(.ultraThinMaterial)
							.opacity(0.3)
							.ignoresSafeArea()
					}
					.animation(.easeInOut(duration: 0.5), value: currentGradient)
				
				ScrollView {
					VStack(spacing: 20) {
						VStack(spacing: 8) {
							Text("PeekDialog Examples")
								.font(.largeTitle)
								.fontWeight(.bold)
							Text("Tap buttons to see different dialog styles")
								.font(.subheadline)
								.foregroundColor(.secondary)
						}
						.padding(.top, 40)
						.padding(.bottom, 30)
						
						// Error Notification Button
						Button {
							withAnimation {
								currentGradient = .error
								errorMessage = "Connection failed. Please check your internet."
							}
						} label: {
							HStack(spacing: 12) {
								Image(systemName: "exclamationmark.triangle.fill")
									.font(.title3)
									.foregroundColor(.white)
								VStack(alignment: .leading, spacing: 4) {
									Text("Error Notification")
										.font(.headline)
										.foregroundColor(.white)
									Text("Default Style • Medium Delay")
										.font(.caption)
										.foregroundColor(.white.opacity(0.8))
								}
								Spacer()
							}
							.padding()
							.frame(maxWidth: .infinity)
							.frame(height: 70)
							.background {
								RoundedRectangle(cornerRadius: 12)
									.fill(
										LinearGradient(
											colors: [.red, .red.opacity(0.8)],
											startPoint: .topLeading,
											endPoint: .bottomTrailing
										)
									)
									.shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
							}
						}
						.buttonStyle(.plain)
						
						// Upload Progress Button
						Button {
							withAnimation {
								currentGradient = .upload
								uploadCompleted = false
								showUpload = true
							}
							
							// Simulate upload completion after 2 seconds
							DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
								withAnimation {
									uploadCompleted = true
								}
								
								// Auto-dismiss after showing checkmark for 1 second
								DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
									showUpload = false
									uploadCompleted = false
								}
							}
						} label: {
							HStack(spacing: 12) {
								Image(systemName: "arrow.up.circle.fill")
									.font(.title3)
									.foregroundColor(.white)
								VStack(alignment: .leading, spacing: 4) {
									Text("Upload Progress")
										.font(.headline)
										.foregroundColor(.white)
									Text("Progress → Checkmark → Auto-dismiss")
										.font(.caption)
										.foregroundColor(.white.opacity(0.8))
								}
								Spacer()
							}
							.padding()
							.frame(maxWidth: .infinity)
							.frame(height: 70)
							.background {
								RoundedRectangle(cornerRadius: 12)
									.fill(
										LinearGradient(
											colors: [.mint, .mint.opacity(0.8)],
											startPoint: .topLeading,
											endPoint: .bottomTrailing
										)
									)
									.shadow(color: .mint.opacity(0.3), radius: 8, x: 0, y: 4)
							}
						}
						.buttonStyle(.plain)
						
						// Toast Notification Button
						Button {
							withAnimation {
								currentGradient = .toast
								showToast = true
							}
						} label: {
							HStack(spacing: 12) {
								Image(systemName: "text.bubble.fill")
									.font(.title3)
									.foregroundColor(.white)
								VStack(alignment: .leading, spacing: 4) {
									Text("Toast Notification")
										.font(.headline)
										.foregroundColor(.white)
									Text("Plain Style • Custom Background")
										.font(.caption)
										.foregroundColor(.white.opacity(0.8))
								}
								Spacer()
							}
							.padding()
							.frame(maxWidth: .infinity)
							.frame(height: 70)
							.background {
								RoundedRectangle(cornerRadius: 12)
									.fill(
										LinearGradient(
											colors: [.gray.opacity(0.8), .black.opacity(0.8)],
											startPoint: .topLeading,
											endPoint: .bottomTrailing
										)
									)
									.shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
							}
						}
						.buttonStyle(.plain)
						
						// iOS 26+ Buttons
						if #available(iOS 26.0, *) {
							// Success Notification Button (iOS 26+)
							Button {
								withAnimation {
									currentGradient = .success
									showSuccess = true
								}
							} label: {
								HStack(spacing: 12) {
									Image(systemName: "checkmark.circle.fill")
										.font(.title3)
										.foregroundColor(.white)
									VStack(alignment: .leading, spacing: 4) {
										Text("Success Notification")
											.font(.headline)
											.foregroundColor(.white)
										Text("Glass Regular • Short Delay")
											.font(.caption)
											.foregroundColor(.white.opacity(0.8))
									}
									Spacer()
								}
								.padding()
								.frame(maxWidth: .infinity)
								.frame(height: 70)
								.background {
									RoundedRectangle(cornerRadius: 12)
										.fill(
											LinearGradient(
												colors: [.green, .green.opacity(0.8)],
												startPoint: .topLeading,
												endPoint: .bottomTrailing
											)
										)
										.shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
								}
							}
							.buttonStyle(.plain)
						}
					}
					.padding(.horizontal, 20)
					.padding(.bottom, 40)
				}
			}
			// Success Notification Dialog (iOS 26+)
			.peekDialog(isPresented: $showSuccess, dismissDelay: .short) {
				Group {
					if #available(iOS 26.0, *) {
						HStack(spacing: 12) {
							Image(systemName: "checkmark.circle.fill")
								.foregroundColor(.green)
								.font(.title2)
							VStack(alignment: .leading, spacing: 4) {
								Text("Saved!")
									.font(.headline)
								Text("Your changes have been saved")
									.font(.subheadline)
									.foregroundColor(.secondary)
							}
							Spacer()
						}
						.padding()
						.dialogStyle(.glassRegular)
					} else {
						HStack(spacing: 12) {
							Image(systemName: "checkmark.circle.fill")
								.foregroundColor(.green)
								.font(.title2)
							VStack(alignment: .leading, spacing: 4) {
								Text("Saved!")
									.font(.headline)
								Text("Your changes have been saved")
									.font(.subheadline)
									.foregroundColor(.secondary)
							}
							Spacer()
						}
						.padding()
					}
				}
			}
			// Error Notification Dialog
			.peekDialog(with: $errorMessage, dismissDelay: .medium) { message in
				HStack(spacing: 12) {
					Image(systemName: "exclamationmark.triangle.fill")
						.foregroundColor(.red)
						.font(.title2)
					VStack(alignment: .leading, spacing: 4) {
						Text("Error")
							.font(.headline)
						Text(message)
							.font(.subheadline)
							.foregroundColor(.secondary)
					}
					Spacer()
				}
				.padding()
			}
			// Upload Progress Dialog
			.peekDialog(isPresented: $showUpload, dismissDelay: .persistent) {
				HStack(spacing: 12) {
					Image(systemName: "arrow.up.circle.fill")
						.foregroundColor(.blue)
						.font(.title2)
					VStack(alignment: .leading, spacing: 4) {
						Text(uploadCompleted ? "Upload Complete!" : "Uploading...")
							.font(.headline)
						Text(uploadCompleted ? "File uploaded successfully" : "File will be uploaded shortly")
							.font(.subheadline)
							.foregroundColor(.secondary)
					}
					Spacer()
					if uploadCompleted {
						Image(systemName: "checkmark.circle.fill")
							.foregroundColor(.green)
							.font(.title2)
					} else {
						ProgressView()
							.progressViewStyle(.circular)
					}
				}
				.padding()
			}
			// Toast Notification Dialog
			.peekDialog(isPresented: $showToast, dismissDelay: .short) {
				Text("Copied to clipboard")
					.font(.body)
					.foregroundColor(.white)
					.padding(.horizontal, 20)
					.padding(.vertical, 12)
					.background {
						RoundedRectangle(cornerRadius: 20)
							.fill(Color.black.opacity(0.8))
					}
					.dialogStyle(.plain)
			}
		}
	}
	return PeekDialogExamplesPreview()
}

