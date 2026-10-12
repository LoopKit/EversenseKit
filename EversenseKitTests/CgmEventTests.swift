@testable import EversenseKit
import Foundation
import LoopKit
import Testing

struct CgmEventTests {
    private let date = Date(timeIntervalSinceReferenceDate: 800_000_000)

    private func alarm(_ code: Alarm) -> ActiveAlarm {
        ActiveAlarm(code: code, datetime: date, glucoseInMgDl: 0, flag: 0, priority: 0)
    }

    @Test func alarmThatStopsGlucoseIsASensorIssue() {
        let events = EversenseCGMManager.cgmEvents(
            for: [alarm(.SensorAwolAlarm), alarm(.LowGlucoseAlarm), alarm(.BatteryStatusAlarm)],
            sensorID: "0a0b",
            transmitterID: "T123",
            sensorEndRecordedFor: nil
        )
        #expect(events == [PersistedCgmEvent(
            date: date,
            type: .sensorIssue,
            deviceIdentifier: "0a0b",
            error: CgmEventError(code: "SensorAwolAlarm"),
            metadata: ["alarmCode": "6"]
        )])
    }

    @Test func transmitterAlarmIsAboutTheTransmitter() {
        let events = EversenseCGMManager.cgmEvents(
            for: [alarm(.EmptyBatteryAlarm)],
            sensorID: "0a0b",
            transmitterID: "T123",
            sensorEndRecordedFor: nil
        )
        #expect(events.map(\.deviceIdentifier) == ["T123"])
    }

    @Test func retiredSensorEndsOnce() {
        let ended = EversenseCGMManager.cgmEvents(
            for: [alarm(.SensorRetiredAlarm), alarm(.SensorGraceAlarm)],
            sensorID: "0a0b",
            transmitterID: "T123",
            sensorEndRecordedFor: nil
        )
        #expect(ended.map(\.type) == [.sensorIssue, .sensorEnd, .sensorIssue])

        let again = EversenseCGMManager.cgmEvents(
            for: [alarm(.SensorRetiredAlarm)],
            sensorID: "0a0b",
            transmitterID: "T123",
            sensorEndRecordedFor: "0a0b"
        )
        #expect(again.map(\.type) == [.sensorIssue])
    }

}
