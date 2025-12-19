import SwiftUI

struct AddProfileView: View {
    @StateObject var viewModel: AddProfileViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showImagePicker = false
    @State private var showCropper = false
    @State private var showDeleteConfirmation = false
    var isOnboarding: Bool = false
    var showCloseButton: Bool = true
    
    var body: some View {
        ZStack {
            Color.background.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 32) {
                // Avatar Placeholder
                VStack(spacing: 16) {
                    ZStack {
                        if let image = viewModel.selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 150, height: 150)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.orange.opacity(0.8))
                                .frame(width: 150, height: 150)
                            
                            Text(viewModel.initials)
                                .font(.system(size: 50, weight: .bold))
                                .foregroundColor(.textSecondary)
                        }
                        
                        Button(action: {
                            viewModel.cropperImage = nil
                            showImagePicker = true
                        }) {
                            Image(systemName: "camera.fill")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.primaryAction)
                            .clipShape(Circle())
                        }
                        .offset(x: 50, y: 65)
                    }
                }
                .padding(.top, 20)
                
                VStack(spacing: 16) {
                    CustomTextField(title: "Name", placeholder: "Enter name", text: $viewModel.name)
                        .textInputAutocapitalization(.words)
                    CustomTextField(title: "Age (Optional)", placeholder: "Enter age", text: $viewModel.age)
                        .keyboardType(.numberPad)
                }
                
                Spacer()
                
                if viewModel.isEditing {
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Text("Delete Profile")
                            .foregroundColor(.red)
                    }
                    .padding(.bottom)
                    .alert(isPresented: $showDeleteConfirmation) {
                        Alert(
                            title: Text("Delete Profile"),
                            message: Text("Are you sure? Associated treatments will be unassigned."),
                            primaryButton: .destructive(Text("Delete")) {
                                viewModel.deleteProfile()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle(viewModel.isEditing ? "Edit Profile" : "Add Profile")
        .navigationBarTitleDisplayMode(.inline)

    // ... (rest of body)

    // toolbar logic:
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if isOnboarding {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Text("Skip")
                            .foregroundColor(.gray)
                    }
                } else if showCloseButton {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: viewModel.saveProfile) {
                    Text("Save")
                        .foregroundColor(.primaryAction)
                }
            }
        }
        .sheet(isPresented: $showImagePicker, onDismiss: {
            // Add a small delay to ensure state is settled and sheet is fully dismissed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if viewModel.cropperImage != nil {
                    showCropper = true
                }
            }
        }) {
            ImagePicker(image: $viewModel.cropperImage)
        }
        .fullScreenCover(isPresented: $showCropper) {
            if let inputImage = viewModel.cropperImage {
                ImageCropperView(image: $viewModel.selectedImage, isPresented: $showCropper, inputImage: inputImage)
            } else {
                ZStack {
                    Color.black.edgesIgnoringSafeArea(.all)
                    Text("Error: Image not loaded")
                        .foregroundColor(.white)
                    Button("Close") {
                        showCropper = false
                    }
                    .padding(.top, 50)
                }
            }
        }
        .onReceive(viewModel.$shouldDismiss) { shouldDismiss in
            if shouldDismiss {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

struct ImageCropperView: View {
    @Binding var image: UIImage?
    @Binding var isPresented: Bool
    var inputImage: UIImage
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack {
                    Spacer()
                    
                    Text("Move and Scale")
                        .foregroundColor(.gray)
                        .font(.headline)
                    
                    Spacer()
                    
                    // Crop Area
                    ZStack {
                        Image(uiImage: inputImage)
                            .resizable()
                            .scaledToFill()
                            .scaleEffect(scale)
                            .offset(offset)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        let delta = value / lastScale
                                        lastScale = value
                                        scale *= delta
                                    }
                                    .onEnded { _ in
                                        lastScale = 1.0
                                        if scale < 0.5 { withAnimation { scale = 0.5 } }
                                    }
                            )
                            .simultaneousGesture(
                                DragGesture()
                                    .onChanged { value in
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                    .onEnded { _ in
                                        lastOffset = offset
                                    }
                            )
                    }
                    .frame(width: 300, height: 300)
                    .clipShape(Circle()) // Visual clip
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .contentShape(Rectangle()) // Ensure gestures work in the whole area
                    
                    Spacer()
                    
                    HStack {
                        Button("Cancel") {
                            isPresented = false
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.gray.opacity(0.5))
                        .cornerRadius(8)
                        
                        Spacer()
                        
                        Button("Choose") {
                            cropImage()
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    .padding()
                    .padding(.bottom, 20)
                }
            }
        }
    }
    
    func cropImage() {
        if #available(iOS 16.0, *) {
            let renderer = ImageRenderer(content:
                Image(uiImage: inputImage)
                    .resizable()
                    .scaledToFill()
                    .scaleEffect(scale)
                    .offset(offset)
                    .frame(width: 300, height: 300)
                    .clipShape(Circle())
            )
            
            renderer.scale = 3.0 // Higher resolution
            
            if let uiImage = renderer.uiImage {
                self.image = uiImage
                self.isPresented = false
            }
        } else {
            // Fallback for older iOS versions: Return original image or implement manual cropping
            // For now, we'll just return the original image to avoid crashes
            print("Cropping requires iOS 16.0+")
            self.image = inputImage
            self.isPresented = false
        }
    }
}
