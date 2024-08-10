//
//  Home.swift
//  FocusFlow
//
//  Created by Evgeniia Komarova on 07.08.2024.
//

import SwiftUI
import SwiftData

struct Home: View {
    @State private var flipClockTime: TimeModel = .init()
    @State private var pickerTime: TimeModel = .init()
    @State private var isStart: Bool = false
    @State private var totalTimeInSeconds: Int = 0
    @State private var timerCount: Int = 0
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @Query(sort: [SortDescriptor(\RecentModel.date, order: .reverse)], animation: .snappy) private var recents: [RecentModel]
    @Environment(\.modelContext) private var context
    
    // Define the gradient background
    private var gradientBackground: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.orange, Color.pink, Color.purple]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Focus Flow")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding(.top, 15)
            
            TimeView()
                .padding(.top, 35)
            
            TimePicker(
                style: .init(.gray.opacity(0.15)),
                hour: $pickerTime.hour,
                minute: $pickerTime.minute,
                seconds: $pickerTime.seconds
            )
            .environment(\.colorScheme, .light)
            .padding(15)
            .background(.white, in: .rect(cornerRadius: 15))
            .onChange(of: pickerTime, { oldValue, newValue in
                flipClockTime = newValue
            })
            .disabledWithOpacity(isStart)
            
            TimerButton()
            
            RecentsView()
                .disabledWithOpacity(isStart)
        }
        .padding(15)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(gradientBackground) // Apply gradient background here
        .onReceive(timer) { _ in
            if isStart {
                if timerCount > 0 {
                    timerCount -= 1
                    updateFlipClock()
                } else {
                    stopTimer()
                }
            } else {
                timer.upstream.connect().cancel()
            }
        }
    }
    
    func updateFlipClock() {
        let hour = (timerCount / 3600) % 24
        let minute = (timerCount / 60) % 60
        let seconds = (timerCount) % 60
        
        flipClockTime = .init(hour: hour, minute: minute, seconds: seconds)
    }
    
    @ViewBuilder
    func RecentsView() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recents")
                .font(.callout)
                .foregroundStyle(.white.opacity(0.8))
                .opacity(recents.isEmpty ? 0 : 1)
            
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(recents) { value in
                        let isHour = value.hour > 0
                        let isSeconds = value.hour == 0 && value.minute == 0 && value.seconds != 0
                        HStack(spacing: 0) {
                            Text(isHour ? "\(value.hour)" : isSeconds ? "\(value.seconds)" : "\(value.minute)")
                            Text(isHour ? "h" : isSeconds ? "s" : "m")
                        }
                        .font(.callout)
                        .foregroundStyle(.black)
                        .frame(width: 50, height: 50)
                        .background(.white, in: .circle)
                        .contentShape(.contextMenuPreview, .circle)
                        .contextMenu {
                            Button("Delete", role: .destructive) {
                                context.delete(value)
                            }
                        }
                        .onTapGesture {
                            withAnimation(.snappy) {
                                pickerTime = .init(hour: value.hour, minute: value.minute, seconds: value.seconds)
                            }
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
        }
    }
    
    @ViewBuilder
    func TimerButton() -> some View {
        Button {
            isStart.toggle()
            if isStart {
                startTimer()
            } else {
                stopTimer()
            }
        } label: {
            Text(!isStart ? "Start Timer" : "Stop Timer")
                .font(.callout)
                .fontWeight(.medium)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.white, in: .rect(cornerRadius: 10))
                .contentShape(.rect(cornerRadius: 10))
        }
        .disabledWithOpacity(flipClockTime.isZero && !isStart)
    }
    func startTimer() {
        totalTimeInSeconds = flipClockTime.totalInSeconds
        if !recents.contains(where: { $0.totalInSeconds == totalTimeInSeconds }) {
            let recent = RecentModel(hour: flipClockTime.hour, minute: flipClockTime.minute, seconds: flipClockTime.seconds)
            context.insert(recent)
        }
        timerCount = totalTimeInSeconds - 1
        updateFlipClock()
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    }
    func stopTimer() {
        isStart = false
        totalTimeInSeconds = 0
        timerCount = 0
        flipClockTime = .init()
        withAnimation(.linear) {
            pickerTime = .init()
        }
        timer.upstream.connect().cancel()
    }
    
    @ViewBuilder
    func TimeView() -> some View {
        let size = CGSize(width: 100, height: 120)
        HStack(spacing: 10) {
            TimeViewHelper("Hours", $flipClockTime.hour, size)
            TimeViewHelper("Minutes", $flipClockTime.minute, size)
            TimeViewHelper("Seconds", $flipClockTime.seconds, size, true)
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    func TimeViewHelper(_ title: String, _ value: Binding<Int>, _ size: CGSize, _ isLast: Bool = false) -> some View {
        VStack(spacing: 10) {
            HStack {
                FlipClockTextEffect(
                    value: value,
                    size: size,
                    fontSize: 60,
                    cornerRadius: 18,
                    foreground: .black,
                    background: .white,
                    animationDuration: 0.8
                )
                
                if !isLast {
                    VStack(spacing: 15) {
                        Circle()
                            .fill(.white)
                            .frame(width: 10, height: 10)
                        
                        Circle()
                            .fill(.white)
                            .frame(width: 10, height: 10)
                    }
                }
            }
            
            Text(title)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .fixedSize()
        }
    }
}

extension View {
    @ViewBuilder
    func disabledWithOpacity(_ condition: Bool) -> some View {
        self
            .disabled(condition)
            .opacity(condition ? 0.5 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: condition)
    }
}

#Preview {
    ContentView()
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        var hexValue = hex
        if hex.hasPrefix("#") {
            hexValue = String(hex.dropFirst())
        }
        let scanner = Scanner(string: hexValue)
        var color: UInt64 = 0
        
        if scanner.scanHexInt64(&color) {
            let red = Double((color & 0xFF0000) >> 16) / 255.0
            let green = Double((color & 0x00FF00) >> 8) / 255.0
            let blue = Double(color & 0x0000FF) / 255.0
            
            self.init(red: red, green: green, blue: blue)
        } else {
            self.init(.gray) // Fallback color
        }
    }
}
