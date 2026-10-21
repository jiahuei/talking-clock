import SwiftUI

struct IntervalPickerView: View {
    @Binding var intervalValue: Int
    @Binding var timeUnit: TimeUnit

    var body: some View {
        VStack(spacing: 12) {
            Text("Speak time every")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                // Interval value picker
                Picker("Interval", selection: $intervalValue) {
                    ForEach(timeUnit.availableIntervals, id: \.self) { value in
                        Text("\(value)").tag(value)
                    }
                }
                .pickerStyle(.menu)
                .frame(minWidth: 60)
                .background(Color(.systemGray6))
                .cornerRadius(8)

                // Time unit picker
                Picker("Unit", selection: $timeUnit) {
                    ForEach(TimeUnit.allCases, id: \.self) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }
                .pickerStyle(.menu)
                .frame(minWidth: 100)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
}

#Preview {
    IntervalPickerView(
        intervalValue: .constant(5),
        timeUnit: .constant(.minutes)
    )
}
