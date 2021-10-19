//  Created by Jesse Vorisek on 10/19/21.
import SwiftUI

// TODO: would be nice to make this (and a few other views some sort of overlay modal).
// Maybe using https://github.com/jankaltoun/CustomModalView
struct RepsPickerView: View {
    typealias Dismissed = (Int) -> Void
    let min: Int
    let max: Int
    let dismissed: Dismissed
    @State var reps: Int
    @Environment(\.presentationMode) private var presentation

    init(initial: Int, min: Int = 0, max: Int = 500, dismissed: @escaping Dismissed) {
        self.min = min
        self.max = max
        self.dismissed = dismissed
        self._reps = State(initialValue: initial)
    }

    var body: some View {
        VStack() {
            Text("Reps Completed").font(.largeTitle)
            Spacer()

            HStack {
                Button("- ", action: {self.reps -= 1}).font(.largeTitle).disabled(self.reps <= self.min)
                Text("\(self.reps)").font(.largeTitle)
                Button(" +", action: {self.reps += 1}).font(.largeTitle).disabled(self.reps >= self.max)
            }

            Spacer()
            HStack {
                Button("Cancel", action: onCancel).font(.callout)
                Spacer()
                Spacer()
                Button("OK", action: onOK).font(.headline)
            }.padding()
        }
    }
    
    private func onCancel() {
        self.presentation.wrappedValue.dismiss()
    }

    private func onOK() {
        self.dismissed(self.reps)
        self.presentation.wrappedValue.dismiss()
    }
}

struct RepsPickerView_Previews: PreviewProvider {
    static var previews: some View {
        RepsPickerView(initial: 5, dismissed: onDismiss)
    }

    static func onDismiss(_ reps: Int) {
    }
}
