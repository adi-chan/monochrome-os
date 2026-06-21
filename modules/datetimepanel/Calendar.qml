// modules/datetimepanel/Calendar.qml
import QtQuick
import Quickshell
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Io
import qs.services as Services

Rectangle {
    id: root
    antialiasing: true
    radius: 14

    property color bgColor: "#2b2b2b"
    property color textColor: "#ffffff"
    property color mutedColor: "#555555"
    property color headerColor: "#ffffff"
    property color todayFill: "#ff3333"
    property color todayText: "#1E1E2E"

    color: bgColor

    implicitWidth: 360
    implicitHeight: 250

    signal dateClicked(int year, int month, int day)

    property int pad: 14
    property int colGap: 10
    property int rowGap: 10

    readonly property var now: new Date()
    property int yearValue: now.getFullYear()
    property int monthValue: now.getMonth()

    function nextMonth() {
        monthValue++
        if (monthValue > 11) {
            monthValue = 0
            yearValue++
        }
    }

    function prevMonth() {
        monthValue--
        if (monthValue < 0) {
            monthValue = 11
            yearValue--
        }
    }

    function monthName(m) {
        return ["January","February","March","April","May","June","July","August","September","October","November","December"][m]
    }

    function daysInMonth(year, month0) { return new Date(year, month0 + 1, 0).getDate() }
    function daysInPrevMonth(year, month0) { return new Date(year, month0, 0).getDate() }

    function mondayOffset(year, month0) {
        return (new Date(year, month0, 1).getDay() + 6) % 7
    }

    function isToday(y, m, d) {
        return now.getFullYear() === y && now.getMonth() === m && now.getDate() === d
    }

    Column {
        anchors.fill: parent
        anchors.margins: root.pad
        spacing: root.rowGap

        RowLayout {
            width: parent.width
            height: 24

            Text {
                text: "‹"
                font.pixelSize: 16
                color: root.textColor
                Layout.alignment: Qt.AlignVCenter

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.prevMonth()
                    cursorShape: Qt.PointingHandCursor
                }
            }

            Item { Layout.fillWidth: true }

            Text {
                text: root.monthName(root.monthValue) + " " + root.yearValue
                font.pixelSize: 14
                font.weight: 600
                color: root.textColor
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "›"
                font.pixelSize: 16
                color: root.textColor
                Layout.alignment: Qt.AlignVCenter

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.nextMonth()
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }

        Grid {
            id: headerGrid
            width: parent.width
            columns: 7
            columnSpacing: root.colGap
            rowSpacing: 0
            property real cellW: Math.floor((width - columnSpacing * 6) / 7)

            Repeater {
                model: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                Text {
                    width: headerGrid.cellW
                    height: 18
                    text: modelData
                    color: root.headerColor
                    font.pixelSize: 12
                    font.weight: 600
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.family: "Adwaita Sans"
                }
            }
        }

        Grid {
            id: daysGrid
            width: parent.width
            height: parent.height - headerGrid.height - root.rowGap - 24
            columns: 7
            columnSpacing: root.colGap
            rowSpacing: root.rowGap

            property int offset: root.mondayOffset(root.yearValue, root.monthValue)
            property int dim: root.daysInMonth(root.yearValue, root.monthValue)
            property int prevDim: root.daysInPrevMonth(root.yearValue, root.monthValue)

            property real cellW: Math.floor((width - columnSpacing * 6) / 7)
            property real cellH: Math.floor((height - rowSpacing * 5) / 6)

            Repeater {
                model: 42

                Item {
                    width: daysGrid.cellW
                    height: daysGrid.cellH

                    property int rawDay: index - daysGrid.offset + 1

                    property bool inCurrent: rawDay >= 1 && rawDay <= daysGrid.dim
                    property bool inPrev: rawDay < 1
                    property bool inNext: rawDay > daysGrid.dim

                    property int displayDay: inCurrent ? rawDay
                                         : (inPrev ? (daysGrid.prevDim + rawDay)
                                                   : (rawDay - daysGrid.dim))

                    property bool today: inCurrent && root.isToday(root.yearValue, root.monthValue, displayDay)

                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height) * 0.95
                        height: width
                        radius: 8
                        color: dayMouse.containsMouse ? "#3a3c4e" : "transparent"
                        antialiasing: true
                        
                        scale: dayMouse.pressed ? 0.9 : (dayMouse.containsMouse ? 1.05 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                        Behavior on color { ColorAnimation { duration: 150 } }

                        MouseArea {
                            id: dayMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                let y = root.yearValue
                                let m = root.monthValue
                                if (parent.parent.inPrev) {
                                    m--
                                    if (m < 0) { m = 11; y-- }
                                } else if (parent.parent.inNext) {
                                    m++
                                    if (m > 11) { m = 0; y++ }
                                }
                                root.dateClicked(y, m, parent.parent.displayDay)
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: parent.parent.displayDay
                            font.family: "Adwaita Sans"
                            font.pixelSize: 13
                            font.weight: parent.parent.today ? 800 : Font.Normal
                            color: parent.parent.today ? root.todayFill
                                                     : (parent.parent.inCurrent ? root.textColor : root.mutedColor)
                        }
                    }
                }
            }
        }
    }
}