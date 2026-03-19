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

                // Date & deity
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
                    if festival.isToday {
                        Text("Today")
                            .font(DharmaFont.caption(12))
                            .foregroundColor(.dharmaGold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.dharmaGold.opacity(0.15))
                            .clipShape(Capsule())
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

                InfoSection(title: "The Story", content: festival.fullStory)
                InfoSection(title: "Why It Matters", content: festival.significance)
                InfoSection(title: "How to Observe", content: festival.howToObserve)

                Spacer(minLength: DharmaSpacing.xxl)
            }
            .padding(DharmaSpacing.lg)
        }
        .background(Color.dharmaBackground)
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
    }

    private func addToCalendar() {
        eventStore.requestFullAccessToEvents { granted, error in
            DispatchQueue.main.async {
                guard granted else { return }

                let event = EKEvent(eventStore: self.eventStore)
                event.title = festival.name
                event.notes = "\(festival.shortDescription)\n\nDeity: \(festival.deity)\n\nHow to observe: \(festival.howToObserve)"
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
        FestivalDetailView(festival: HinduFestival.sampleData[0])
    }
}
