import SwiftUI

struct AddChild: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var user: MockUser
    
    @State private var childName = ""
    @State private var childAge = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Child Information")) {
                    TextField("Name", text: $childName)
                    TextField("Age", text: $childAge)
                        .keyboardType(.numberPad)
                }
                
                if showError {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button("Add Child") {
                        addChild()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Add Child")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func addChild() {
        // Validate input
        guard !childName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showError = true
            errorMessage = "Please enter a name"
            return
        }
        
        guard let age = Int(childAge), age >= 0, age <= 18 else {
            showError = true
            errorMessage = "Please enter a valid age (0-18)"
            return
        }
        
        // Add the child to the user's children array
        let newChild = MockChild(
            id: UUID().uuidString,
            name: childName.trimmingCharacters(in: .whitespacesAndNewlines),
            age: age
        )
        
        if user.children != nil {
            user.children?.append(newChild)
        } else {
            user.children = [newChild]
        }
        
        // Dismiss the sheet
        presentationMode.wrappedValue.dismiss()
    }
}
