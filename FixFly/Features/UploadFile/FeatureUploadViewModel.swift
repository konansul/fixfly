//
//  FeatureUploadViewModel.swift
//  FixFly
//
//  Created by Kanan Sultanov on 14.03.26.
//

import SwiftUI
import PhotosUI
import Combine

@MainActor
final class FeatureUploadViewModel: ObservableObject {
    let config: FeatureConfig

    @Published var selectedUIImage: UIImage?
    @Published var selectedItem: PhotosPickerItem?
    
    @Published var resultUIImage: UIImage?
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    @Published var showResult = false
    @Published var showCamera = false

    init(config: FeatureConfig) {
        self.config = config
    }

    func handleCameraImage(_ image: UIImage) {
        self.selectedUIImage = image
        Task { await processIfPossible() }
    }

    func handlePhotoSelection(_ newItem: PhotosPickerItem?) {
        guard let newItem else { return }
        Task {
            await loadUIImage(from: newItem)
            await processIfPossible()
        }
    }

    private func processIfPossible() async {
        guard let input = selectedUIImage else { return }
        guard !isProcessing else { return }

        isProcessing = true
        errorMessage = nil
        resultUIImage = nil

        do {
            let output = try await MultipartAPI.shared.processImage(
                endpointPath: config.endpointPath,
                image: input,
                extraFields: config.extraFields,
                accept: config.accepts
            )

            await WalletManager.shared.refreshBalance()
            
            self.resultUIImage = output
            self.isProcessing = false
            self.showResult = true
        } catch {
            self.errorMessage = error.localizedDescription
            self.isProcessing = false
        }
    }

    private func loadUIImage(from item: PhotosPickerItem) async {
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let img = UIImage(data: data) {
                self.selectedUIImage = img
            } else {
                self.errorMessage = "Could not load image from Photos."
            }
        } catch {
            self.errorMessage = "Failed to load image: \(error.localizedDescription)"
        }
    }
}
