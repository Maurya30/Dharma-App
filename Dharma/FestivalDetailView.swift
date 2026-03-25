import SwiftUI
import EventKit
import EventKitUI

struct FestivalDetailView: View {
    let festival: HinduFestival
    @State private var showEventEditor = false
    @State private var eventStore = EKEventStore()
    @State private var eventToEdit: EKEvent?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DharmaSpacing.lg) {

                // Date, deity & type
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(festival.date.formatted(date: .complete, time: .omitted))
                            .font(DharmaFont.caption(13))
                            .foregroundColor(.dharmaGold)
                        Text("Deity: \(festival.deity)")
                            .font(DharmaFont.caption(13))
                            .foregroundColor(.dharmaTextMuted)
                            .italic()
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(festival.type.rawValue)
                            .font(DharmaFont.caption(10))
                            .foregroundColor(.dharmaGold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.dharmaGold.opacity(0.12))
                            .clipShape(Capsule())

                        if let countdown = festival.countdownText {
                            Text(countdown)
                                .font(DharmaFont.caption(11))
                                .foregroundColor(.dharmaGold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.dharmaGold.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                }

                // Add to Calendar button
                Button {
                    addToCalendar()
                } label: {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                        Text("Add to Apple Calendar")
                            .font(DharmaFont.body(15))
                    }
                    .foregroundColor(.dharmaGold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.dharmaGold.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: DharmaRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: DharmaRadius.md)
                            .strokeBorder(Color.dharmaGold.opacity(0.3), lineWidth: 1)
                    )
                }

                Divider().background(Color.dharmaDivider)

                InfoSection(title: "About", content: festival.description)

                InfoSection(title: "Significance", content: festival.significance)

                Spacer(minLength: DharmaSpacing.xxl)
            }
            .padding(DharmaSpacing.lg)
        }
        .scrollContentBackground(.hidden)
        .navigationTitle(festival.name)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            eventStore.requestFullAccessToEvents { _, _ in }
        }
        .sheet(isPresented: $showEventEditor) {
            if let event = eventToEdit {
                EventEditViewController(event: event, eventStore: eventStore)
            }
        }
        .transparentNavigationBar()
        .dharmaBackground()
    }

    private func addToCalendar() {
        eventStore.requestFullAccessToEvents { granted, error in
            DispatchQueue.main.async {
                guard granted else { return }

                let event = EKEvent(eventStore: self.eventStore)
                event.title = festival.name
                event.notes = "\(festival.description)\n\nDeity: \(festival.deity)\n\nSignificance: \(festival.significance)"
                event.startDate = festival.date
                event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: festival.date)
                event.isAllDay = true
                event.calendar = self.eventStore.defaultCalendarForNewEvents

                self.eventToEdit = event
                self.showEventEditor = true
            }
        }
    }
}

// MARK: - EventKit UI Wrapper
struct EventEditViewController: UIViewControllerRepresentable {
    let event: EKEvent
    let eventStore: EKEventStore
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let controller = EKEventEditViewController()
        controller.event = event
        controller.eventStore = eventStore
        controller.editViewDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: EKEventEditViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, EKEventEditViewDelegate {
        let parent: EventEditViewController

        init(_ parent: EventEditViewController) {
            self.parent = parent
        }

        func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
            parent.dismiss()
        }
    }
}

// MARK: - Info Section
struct InfoSection: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(DharmaFont.caption(11))
                .foregroundColor(.dharmaGold)
                .textCase(.uppercase)
                .kerning(0.8)

            Text(content)
                .font(DharmaFont.body())
                .foregroundColor(.dharmaTextBody)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DharmaSpacing.md)
        .background(Color.dharmaSurface)
        .clipShape(RoundedRectangle(cornerRadius: DharmaRadius.md))
    }
}

#Preview {
    NavigationStack {
        FestivalDetailView(festival: allFestivals[0])
    }
}
