import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    layerNamespacePlugin: "dolar-blue"

    property string buyValue: "..."
    property string sellValue: "..."
    property var allRates: ({})
    property bool loading: true
    property string lastUpdate: ""

    // Settings
    property string rateType: pluginData.rateType || "blue"
    property int refreshInterval: pluginData.refreshInterval || 10
    property string buttonText: pluginData.buttonText !== undefined ? pluginData.buttonText : "Dolar Hoy"
    property string buttonUrl: pluginData.buttonUrl !== undefined ? pluginData.buttonUrl : "https://dolarhoy.com"
    property string buttonText2: pluginData.buttonText2 !== undefined ? pluginData.buttonText2 : "Dolarito"
    property string buttonUrl2: pluginData.buttonUrl2 !== undefined ? pluginData.buttonUrl2 : "https://dolarito.ar"
    property string displayTitle: {
        switch(rateType) {
            case "blue": return "Dolar Blue";
            case "oficial": return "Dolar Oficial";
            case "blue_euro": return "Euro Blue";
            case "oficial_euro": return "Euro Oficial";
            default: return "Dolar Blue";
        }
    }

    property url displayIconSource: rateType.indexOf("euro") !== -1
        ? Qt.resolvedUrl("euro.svg")
        : Qt.resolvedUrl("dollar.svg")

    onRateTypeChanged: fetchData()

    Timer {
        interval: root.refreshInterval * 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: fetchData()
    }

    function fetchData() {
        root.loading = true;
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText);
                        root.allRates = response;
                        var data = response[root.rateType];
                        if (data) {
                            root.buyValue = data.value_buy.toString();
                            root.sellValue = data.value_sell.toString();
                            root.lastUpdate = Qt.formatDateTime(new Date(), "HH:mm");
                            root.loading = false;
                        }
                    } catch (e) {
                        console.error("Error parsing JSON:", e);
                    }
                } else {
                    console.error("Error fetching data:", xhr.status, xhr.statusText);
                }
            }
        }
        xhr.open("GET", "https://api.bluelytics.com.ar/v2/latest");
        xhr.send();
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            DankSVGIcon {
                source: root.displayIconSource
                size: Theme.iconSize - 7
                anchors.verticalCenter: parent.verticalCenter
                colorOverride: root.loading ? (Theme.widgetIconColor || Theme.surfaceText) : Theme.primary
            }

            StyledText {
                text: root.loading ? "..." : "$" + root.buyValue
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.primary
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: "/"
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: root.loading ? "..." : "$" + root.sellValue
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        Item {
            implicitWidth: col.implicitWidth
            implicitHeight: col.implicitHeight

            Column {
                id: col
                anchors.centerIn: parent
                spacing: 2

                DankSVGIcon {
                    source: root.displayIconSource
                    size: Theme.iconSize
                    anchors.horizontalCenter: parent.horizontalCenter
                    colorOverride: root.loading ? (Theme.widgetIconColor || Theme.surfaceText) : Theme.primary
                }

                StyledText {
                    text: root.loading ? "..." : "$" + root.buyValue
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.primary
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                StyledText {
                    text: root.loading ? "..." : "$" + root.sellValue
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceText
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

    // Rounded value badge (Compra / Venta), styled like the GitHub Notifier count badge
    component ValueBadge: Rectangle {
        property string label: ""
        property string value: "..."
        property color accentColor: Theme.primary

        width: badgeContent.width + Theme.spacingM
        height: 24
        radius: 12
        color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15)

        Row {
            id: badgeContent
            anchors.centerIn: parent
            spacing: 4

            StyledText {
                text: label
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: "$" + value
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Bold
                color: accentColor
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // Rate row modeled after GitHub Notifier's StatRow: accent bar + icon + title + badges
    component RateStatRow: Item {
        id: statRow

        property string title: ""
        property url iconSource: Qt.resolvedUrl("dollar.svg")
        property string buy: "..."
        property string sell: "..."
        property color accentColor: Theme.primary

        width: parent.width
        height: 44

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacingS

            Rectangle {
                width: 4
                height: 22
                radius: 2
                color: accentColor
                anchors.verticalCenter: parent.verticalCenter
            }

            DankSVGIcon {
                source: iconSource
                size: 20
                colorOverride: accentColor
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: title
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Bold
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacingXS

            ValueBadge {
                label: "C"
                value: statRow.buy
                accentColor: statRow.accentColor
                anchors.verticalCenter: parent.verticalCenter
            }

            ValueBadge {
                label: "V"
                value: statRow.sell
                accentColor: statRow.accentColor
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    popoutContent: Component {
        Column {
            width: parent.width
            spacing: Theme.spacingM
            topPadding: Theme.spacingM
            bottomPadding: Theme.spacingM

            // Header card
            Item {
                width: parent.width
                height: 68

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.cornerRadius * 1.5
                    gradient: Gradient {
                        GradientStop {
                            position: 0.0
                            color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
                        }
                        GradientStop {
                            position: 1.0
                            color: Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.08)
                        }
                    }
                    border.width: 1
                    border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.25)
                }

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacingM
                    anchors.right: refreshButton.left
                    anchors.rightMargin: Theme.spacingS
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacingM

                    Rectangle {
                        width: 40
                        height: 40
                        radius: 20
                        anchors.verticalCenter: parent.verticalCenter
                        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)

                        DankSVGIcon {
                            source: root.displayIconSource
                            size: 22
                            anchors.centerIn: parent
                            colorOverride: Theme.primary
                        }
                    }

                    Column {
                        width: parent.width - 40 - Theme.spacingM
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        StyledText {
                            width: parent.width
                            text: "Cotizaciones"
                            font.bold: true
                            font.pixelSize: Theme.fontSizeLarge
                            color: Theme.surfaceText
                            elide: Text.ElideRight
                        }

                        StyledText {
                            width: parent.width
                            text: root.loading ? "Actualizando..." : (root.lastUpdate ? "Actualizado " + root.lastUpdate : "Bluelytics")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                            elide: Text.ElideRight
                        }
                    }
                }

                // Refresh button
                Item {
                    id: refreshButton
                    width: 38
                    height: 38
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.spacingM
                    anchors.verticalCenter: parent.verticalCenter
                    scale: refreshArea.pressed ? 0.9 : (refreshArea.containsMouse ? 1.1 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                    MouseArea {
                        id: refreshArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.fetchData()
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.cornerRadius
                        color: refreshArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.4)
                        border.width: 1
                        border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, refreshArea.containsMouse ? 0.3 : 0.15)
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                    }

                    DankIcon {
                        id: refreshIcon
                        name: "refresh"
                        size: 20
                        color: Theme.primary
                        anchors.centerIn: parent

                        RotationAnimation on rotation {
                            from: 0
                            to: 360
                            duration: 1000
                            loops: Animation.Infinite
                            running: root.loading
                        }
                    }
                }
            }

            // Rates
            RateStatRow {
                title: "Dolar Blue"
                iconSource: Qt.resolvedUrl("dollar.svg")
                accentColor: Theme.primary
                buy: root.allRates.blue ? root.allRates.blue.value_buy : "..."
                sell: root.allRates.blue ? root.allRates.blue.value_sell : "..."
            }

            RateStatRow {
                title: "Dolar Oficial"
                iconSource: Qt.resolvedUrl("dollar.svg")
                accentColor: Theme.primary
                buy: root.allRates.oficial ? root.allRates.oficial.value_buy : "..."
                sell: root.allRates.oficial ? root.allRates.oficial.value_sell : "..."
            }

            RateStatRow {
                title: "Euro Blue"
                iconSource: Qt.resolvedUrl("euro.svg")
                accentColor: Theme.secondary
                buy: root.allRates.blue_euro ? root.allRates.blue_euro.value_buy : "..."
                sell: root.allRates.blue_euro ? root.allRates.blue_euro.value_sell : "..."
            }

            RateStatRow {
                title: "Euro Oficial"
                iconSource: Qt.resolvedUrl("euro.svg")
                accentColor: Theme.secondary
                buy: root.allRates.oficial_euro ? root.allRates.oficial_euro.value_buy : "..."
                sell: root.allRates.oficial_euro ? root.allRates.oficial_euro.value_sell : "..."
            }

            // Custom Buttons
            Row {
                visible: (root.buttonText && root.buttonUrl) || (root.buttonText2 && root.buttonUrl2)
                width: parent.width
                height: visible ? 40 : 0
                spacing: Theme.spacingM

                // First Button
                Rectangle {
                    visible: root.buttonText && root.buttonUrl
                    width: root.buttonText2 && root.buttonUrl2 ? (parent.width - Theme.spacingM) / 2 : parent.width
                    height: 40
                    radius: Theme.cornerRadius * 1.5
                    color: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, buttonMouse1.containsMouse ? 0.8 : 0.5)
                    border.width: 1
                    border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Row {
                        anchors.centerIn: parent
                        spacing: Theme.spacingS

                        DankIcon {
                            name: "open_in_new"
                            size: 18
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: root.buttonText
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: buttonMouse1
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.buttonUrl) {
                                Quickshell.execDetached(["xdg-open", root.buttonUrl])
                                root.closePopout()
                            }
                        }
                    }
                }

                // Second Button
                Rectangle {
                    visible: root.buttonText2 && root.buttonUrl2
                    width: root.buttonText && root.buttonUrl ? (parent.width - Theme.spacingM) / 2 : parent.width
                    height: 40
                    radius: Theme.cornerRadius * 1.5
                    color: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, buttonMouse2.containsMouse ? 0.8 : 0.5)
                    border.width: 1
                    border.color: Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.15)
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Row {
                        anchors.centerIn: parent
                        spacing: Theme.spacingS

                        DankIcon {
                            name: "open_in_new"
                            size: 18
                            color: Theme.secondary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: root.buttonText2
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                            color: Theme.secondary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: buttonMouse2
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.buttonUrl2) {
                                Quickshell.execDetached(["xdg-open", root.buttonUrl2])
                                root.closePopout()
                            }
                        }
                    }
                }
            }
        }
    }

    popoutWidth: 420
    popoutHeight: (root.buttonText && root.buttonUrl) || (root.buttonText2 && root.buttonUrl2) ? 380 : 320
}
