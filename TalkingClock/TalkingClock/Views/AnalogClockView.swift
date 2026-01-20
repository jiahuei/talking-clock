import SwiftUI

struct AnalogClockView: View {
    let time: Date

    private var hourAngle: Angle {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)
        let hourIn12 = hour % 12
        let degrees = Double(hourIn12) * 30 + Double(minute) * 0.5
        return .degrees(degrees - 90)
    }

    private var minuteAngle: Angle {
        let calendar = Calendar.current
        let minute = calendar.component(.minute, from: time)
        let second = calendar.component(.second, from: time)
        let degrees = Double(minute) * 6 + Double(second) * 0.1
        return .degrees(degrees - 90)
    }

    private var secondAngle: Angle {
        let calendar = Calendar.current
        let second = calendar.component(.second, from: time)
        let degrees = Double(second) * 6
        return .degrees(degrees - 90)
    }

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - 10

            // Draw clock face
            drawClockFace(context: context, center: center, radius: radius)

            // Draw hour markers
            drawHourMarkers(context: context, center: center, radius: radius)

            // Draw hands
            drawHourHand(context: context, center: center, radius: radius)
            drawMinuteHand(context: context, center: center, radius: radius)
            drawSecondHand(context: context, center: center, radius: radius)

            // Draw center dot
            drawCenterDot(context: context, center: center)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func drawClockFace(context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        let circle = Path(ellipseIn: CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        ))
        context.stroke(circle, with: .color(.primary.opacity(0.3)), lineWidth: 2)
    }

    private func drawHourMarkers(context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        for hour in 0..<12 {
            let angle = Angle.degrees(Double(hour) * 30 - 90)
            let isMainHour = hour % 3 == 0

            let innerRadius = radius - (isMainHour ? 20 : 12)
            let outerRadius = radius - 4

            let startPoint = CGPoint(
                x: center.x + innerRadius * cos(angle.radians),
                y: center.y + innerRadius * sin(angle.radians)
            )
            let endPoint = CGPoint(
                x: center.x + outerRadius * cos(angle.radians),
                y: center.y + outerRadius * sin(angle.radians)
            )

            var path = Path()
            path.move(to: startPoint)
            path.addLine(to: endPoint)

            context.stroke(
                path,
                with: .color(.primary),
                lineWidth: isMainHour ? 3 : 1.5
            )
        }
    }

    private func drawHourHand(context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        let length = radius * 0.5
        let endPoint = CGPoint(
            x: center.x + length * cos(hourAngle.radians),
            y: center.y + length * sin(hourAngle.radians)
        )

        var path = Path()
        path.move(to: center)
        path.addLine(to: endPoint)

        context.stroke(path, with: .color(.primary), style: StrokeStyle(lineWidth: 4, lineCap: .round))
    }

    private func drawMinuteHand(context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        let length = radius * 0.7
        let endPoint = CGPoint(
            x: center.x + length * cos(minuteAngle.radians),
            y: center.y + length * sin(minuteAngle.radians)
        )

        var path = Path()
        path.move(to: center)
        path.addLine(to: endPoint)

        context.stroke(path, with: .color(.primary), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
    }

    private func drawSecondHand(context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        let length = radius * 0.8
        let endPoint = CGPoint(
            x: center.x + length * cos(secondAngle.radians),
            y: center.y + length * sin(secondAngle.radians)
        )

        var path = Path()
        path.move(to: center)
        path.addLine(to: endPoint)

        context.stroke(path, with: .color(.red), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
    }

    private func drawCenterDot(context: GraphicsContext, center: CGPoint) {
        let dotRadius: CGFloat = 5
        let circle = Path(ellipseIn: CGRect(
            x: center.x - dotRadius,
            y: center.y - dotRadius,
            width: dotRadius * 2,
            height: dotRadius * 2
        ))
        context.fill(circle, with: .color(.primary))
    }
}

#Preview {
    AnalogClockView(time: Date())
        .frame(width: 200, height: 200)
        .padding()
}
