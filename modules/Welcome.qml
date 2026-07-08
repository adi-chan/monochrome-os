import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import qs.services as Services

PanelWindow {
    id: root
    
    visible: false
    color: "transparent"
    
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    
    exclusiveZone: -1
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    
    property real animScale: 0.95
    property real animOpacity: 0.0
    
    Behavior on animScale { SpringAnimation { spring: 3.5; damping: 0.35; epsilon: 0.01 } }
    Behavior on animOpacity { NumberAnimation { duration: 300 } }
    
    property string activeQuote: ""
    property string activeAuthor: ""
    property string greeting: "Welcome back, Nick."
    property string remindersText: ""
    property string currentDateString: Qt.formatDate(new Date(), "dddd, MMMM d")
    
    property var quotes: [
        { text: "What is Evil? Whatever Springs From Weakness", author: "Friedrich Nietzsche" },
        { text: "It Takes a Great Deal and Skill to Conceal One’s Talent and Skill.", author: "François de La Rochefoucauld" },
        { text: "Man is an Animal that Makes Bargains: No Other Animal Does This – No Dog Exchanges Bones with Another.", author: "Adam Smith" },
        { text: "We Should Not be Upset that Others Hide the Truth from Us, When We Hide it from Ourselves.", author: "François de La Rochefoucauld" },
        { text: "Hell is Other People", author: "Jean-Paul Sartre" },
        { text: "There are Two Kinds of Lies; One concerns an Accomplished Fact, the Other concerns a Future Duty.", author: "Jean-Jacques Rousseau" },
        { text: "Nothing is as Dangerous as an Ignorant Friend; A Wise Enemy is to be Preferred.", author: "Jean de La Fontaine" },
        { text: "Abandon All Hope, Ye Who Enter Here.", author: "Dante Alighieri" },
        { text: "Man is Condemned to be Free.", author: "Jean-Paul Sartre" },
        { text: "Every Man has in Himself the Most Dangerous Traitor of All.", author: "Søren Kierkegaard" },
        { text: "What People Commonly call Fate is Mostly their Own Stupidity.", author: "Arthur Schopenhauer" },
        { text: "A Genius Lives Only One Story Above Madness.", author: "Arthur Schopenhauer" },
        { text: "Remember to Keep a Clear Head in Difficult Times", author: "Horace" },
        { text: "There Are Two Main Human Sins from Which All the Others Derive: Impatience and Indolence.", author: "Franz Kafka" },
        { text: "The Greatest Souls Are Capable of the Greatest Vices as Well as the Greatest Virtues.", author: "René Descartes" },
        { text: "The Material Has to Be Created.", author: "Florence Nightingale" },
        { text: "Every Failure is a Step to Success", author: "William Whewell" },
        { text: "Adversity Is The First Path To Truth", author: "Lord Byron" },
        { text: "To Doubt Everything or To Believe Everything are Two Equally Convenient Solutions; Both Dispense with the Necessity of Reflection.", author: "Henri Poincaré" },
        { text: "The Wound Is at Her Heart.", author: "Aeneis" },
        { text: "If You Make a Mistake and Do Not Correct It, This Is Called a Mistake.", author: "The Analects" },
        { text: "People, Often Deceived by An Illusive Good, Desire Their Own Ruin.", author: "Niccolò Machiavelli" },
        { text: "A Man Who Cannot Command Himself Always Remains a Slave.", author: "Johann Wolfgang von Goethe" },
        { text: "Force Without Wisdom Falls of Its Own Weight.", author: "Horace" },
        { text: "The Worst Enemy You Can Meet Will Always Be Yourself.", author: "Friedrich Nietzsche" },
        { text: "The Strongest Principle of Growth Lies in the Human Choice.", author: "George Eliot" },
        { text: "A Man is a Wolf to Another Man", author: "Latin Proverb" },
        { text: "We Never Forget What We Endeavor to Forget.", author: "Margenrote" },
        { text: "To Work You Have The Right, But Not To Fruits Thereof", author: "Bhagavad Gita" },
        { text: "Fortune Favours the Bold", author: "Vergilius" },
        { text: "It’s Better to Suffer an Injustice than To Do an Injustice.", author: "Cicero" },
        { text: "People Will Do Anything, No Matter How Absurd, In Order to Avoid Facing Their Own Souls", author: "Carl Gustav Yung" },
        { text: "Those Who Cannot Remember the Past Are Condemned to Repeat It", author: "George Santayana" },
        { text: "Extreme Justice is Extreme Injustice", author: "Marcus Tullius Cicero" },
        { text: "The First Cause of Absurd Conclusions I Ascribe to the Want of Method.", author: "Thomas Hobbes" },
        { text: "There is only one rule for love. It is to lead the loved ones to happiness.", author: "Stendhal" },
        { text: "Change Your Desires Rather than the Order of the World", author: "Descartes" },
        { text: "Love Is the Greatest Teacher", author: "Pliny the Younger" }
    ]

    Process {
        id: lockProc
        command: ["bash", "-c", "if [ ! -f /tmp/qs_welcome_shown ]; then touch /tmp/qs_welcome_shown; echo 'show'; else echo 'hide'; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "show") {
                    root.visible = true;
                    let hour = new Date().getHours();
                    if (hour < 12) root.greeting = "Good Morning, Nick.";
                    else if (hour < 18) root.greeting = "Good Afternoon, Nick.";
                    else root.greeting = "Good Evening, Nick.";
                    
                    let qIndex = Math.floor(Math.random() * root.quotes.length);
                    root.activeQuote = root.quotes[qIndex].text;
                    root.activeAuthor = root.quotes[qIndex].author;
                    
                    loadRemindersProc.running = true;
                    
                    root.animScale = 1.0;
                    root.animOpacity = 1.0;
                } else {
                    root.destroy();
                }
            }
        }
    }
    
    Process {
        id: loadRemindersProc
        command: ["bash", "-c", "cat ~/.config/quickshell/assets/reminders.cache 2>/dev/null || echo ''"]
        stdout: StdioCollector {
            onStreamFinished: {
                let out = text.trim();
                if (out === "") root.remindersText = "No notes or reminders for today. You're all caught up!";
                else root.remindersText = out;
            }
        }
    }
    
    Process {
        id: clearRemindersProc
        command: ["rm", "-f", Quickshell.env("HOME") + "/.config/quickshell/assets/reminders.cache"]
    }
    
    Component.onCompleted: {
        lockProc.running = true;
    }
    
    function closeScreen() {
        root.animOpacity = 0.0;
        root.animScale = 0.95;
        closeTimer.start();
    }
    
    Timer {
        id: closeTimer
        interval: 300
        onTriggered: {
            root.destroy();
        }
    }
    
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.6)
        opacity: root.animOpacity
        
        MouseArea {
            anchors.fill: parent
            // block clicks to desktop
        }
        
        Item {
            width: 1000
            height: 600
            anchors.centerIn: parent
            scale: root.animScale
            
            Rectangle {
                anchors.fill: parent
                radius: 16
                color: Services.Theme.bg
                border.color: Services.Theme.border
                border.width: 1
                
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowOpacity: 0.4
                    shadowBlur: 1.5
                    shadowVerticalOffset: 15
                }
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 50
                    spacing: 50
                    
                    // LEFT COLUMN (Greeting & Quote)
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: parent.width * 0.55
                        
                        Text {
                            text: root.currentDateString
                            font.pixelSize: 20
                            color: Services.Theme.subtext
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1
                        }
                        
                        Item { Layout.preferredHeight: 10 }
                        
                        Text {
                            Layout.fillWidth: true
                            text: root.greeting
                            font.pixelSize: 56
                            font.bold: true
                            color: Services.Theme.text
                            wrapMode: Text.WordWrap
                            lineHeight: 1.1
                        }
                        
                        Item { Layout.fillHeight: true }
                        
                        Text {
                            Layout.fillWidth: true
                            text: "“" + root.activeQuote + "”"
                            font.pixelSize: 24
                            font.italic: true
                            color: Services.Theme.text
                            wrapMode: Text.WordWrap
                            lineHeight: 1.4
                        }
                        
                        Item { Layout.preferredHeight: 5 }
                        
                        Text {
                            Layout.fillWidth: true
                            text: "— " + root.activeAuthor
                            font.pixelSize: 18
                            color: Services.Theme.subtext
                        }
                        
                        Item { Layout.preferredHeight: 20 }
                    }
                    
                    // DIVIDER
                    Rectangle {
                        Layout.fillHeight: true
                        width: 1
                        color: Services.Theme.border
                        opacity: 0.5
                    }
                    
                    // RIGHT COLUMN (Reminders & Actions)
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: parent.width * 0.45
                        
                        Item { Layout.preferredHeight: 10 }
                        
                        Text {
                            text: "TODAY's NOTES"
                            font.pixelSize: 16
                            font.bold: true
                            font.letterSpacing: 2
                            color: Services.Theme.subtext
                        }
                        
                        Item { Layout.preferredHeight: 15 }
                        
                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            contentWidth: availableWidth
                            
                            Text {
                                width: parent.width
                                text: root.remindersText
                                color: Services.Theme.text
                                font.pixelSize: 18
                                wrapMode: Text.WordWrap
                                lineHeight: 1.6
                            }
                        }
                        
                        Item { Layout.preferredHeight: 25 }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 20
                            
                            Rectangle {
                                Layout.fillWidth: true
                                height: 50
                                radius: 8
                                color: "transparent"
                                border.color: Services.Theme.border
                                border.width: 2
                                Text {
                                    anchors.centerIn: parent
                                    text: "Clear & Start"
                                    color: Services.Theme.text
                                    font.pixelSize: 16
                                    font.bold: true
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        clearRemindersProc.running = true;
                                        root.closeScreen();
                                    }
                                }
                            }
                            
                            Rectangle {
                                Layout.fillWidth: true
                                height: 50
                                radius: 8
                                color: Services.Theme.text
                                Text {
                                    anchors.centerIn: parent
                                    text: "Start Day"
                                    color: Services.Theme.bg
                                    font.pixelSize: 16
                                    font.bold: true
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.closeScreen();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
