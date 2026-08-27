import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
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
    property bool hasError: false
    property string errorMessage: ""
    property var lastUpdated: null
    // Set by the manual refresh button so the toast only fires for a refresh
    // the user actually asked for, not for every periodic tick.
    property bool manualRefresh: false
    property string toastText: ""

    // Settings
    property string rateType: pluginData.rateType || "blue"
    property int refreshInterval: pluginData.refreshInterval || 10
    property string buttonText: pluginData.buttonText !== undefined ? pluginData.buttonText : "Dolar Hoy"
    property string buttonUrl: pluginData.buttonUrl !== undefined ? pluginData.buttonUrl : "https://dolarhoy.com"
    property string buttonText2: pluginData.buttonText2 !== undefined ? pluginData.buttonText2 : "Dolarito"
    property string buttonUrl2: pluginData.buttonUrl2 !== undefined ? pluginData.buttonUrl2 : "https://dolarito.ar"
    property string timeFormat: pluginData.timeFormat || "system"
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

    Timer {
        id: toastTimer
        interval: 1800
    }

    // Guards against a request that never completes leaving `loading` latched.
    Timer {
        id: loadingWatchdog
        interval: 20000
        repeat: false
        running: root.loading
        onTriggered: root.failRefresh("Timed out talking to bluelytics. Will retry.")
    }

    function showToast(msg) {
        root.toastText = msg;
        toastTimer.restart();
    }

    function getEffectiveTimeFormat() {
        if (root.timeFormat === "12h") return "12h";
        if (root.timeFormat === "24h") return "24h";

        const sysFmt = Qt.locale().timeFormat(Locale.ShortFormat);
        return (sysFmt.indexOf("H") !== -1 || sysFmt.indexOf("k") !== -1) ? "24h" : "12h";
    }

    function formatHeaderTime(dateObj) {
        if (!dateObj) return "";
        return Qt.formatTime(dateObj, getEffectiveTimeFormat() === "24h" ? "HH:mm" : "h:mm AP");
    }

    function rateFor(key) {
        return root.allRates && root.allRates[key] ? root.allRates[key] : null;
    }

    function completeRefresh() {
        const wasManual = root.manualRefresh;
        root.manualRefresh = false;
        root.loading = false;
        root.hasError = false;
        root.errorMessage = "";
        root.lastUpdated = new Date();

        if (wasManual)
            root.showToast("Cotizaciones actualizadas");
    }

    // Every failure path lands here. Before, only the success path cleared
    // `loading`, so a failed request or a missing key left the widget stuck on
    // "..." for the rest of the session with nothing on screen to say why.
    function failRefresh(msg) {
        root.manualRefresh = false;
        root.loading = false;
        root.hasError = true;
        root.errorMessage = msg;
    }

    function fetchData() {
        root.loading = true;
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;

            if (xhr.status !== 200) {
                root.failRefresh("Could not reach bluelytics (HTTP " + xhr.status + ").");
                return;
            }

            let response;
            try {
                response = JSON.parse(xhr.responseText);
            } catch (e) {
                root.failRefresh("Bluelytics returned a malformed response.");
                return;
            }

            root.allRates = response;
            const data = response[root.rateType];
            if (!data) {
                root.failRefresh("No rate available for \"" + root.rateType + "\".");
                return;
            }

            root.buyValue = data.value_buy.toString();
            root.sellValue = data.value_sell.toString();
            root.completeRefresh();
        };
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

    // Row for one rate. Clicking it makes that rate the one shown in the bar,
    // which until now was only reachable from the settings screen.
    component RateRow: Item {
        id: rateRow

        property string rateKey: ""
        property string title: ""
        property url iconSource: Qt.resolvedUrl("dollar.svg")
        property color accentColor: Theme.primary
        property int index: 0
        property int total: 4

        readonly property var rate: root.rateFor(rateKey)
        readonly property bool isCurrent: root.rateType === rateKey
        readonly property bool isHovered: rateMa.containsMouse
        readonly property bool isFirst: index === 0
        readonly property bool isLast: index === total - 1

        width: parent.width
        height: 52

        Shape {
            id: rateBg
            anchors.fill: parent

            readonly property real innerRadius: 6
            readonly property real outerRadius: Theme.cornerRadius || 12
            readonly property real topR: rateRow.isHovered ? (height / 2) : (rateRow.isFirst ? outerRadius : innerRadius)
            readonly property real bottomR: rateRow.isHovered ? (height / 2) : (rateRow.isLast ? outerRadius : innerRadius)

            property real topRAnim: topR
            Behavior on topRAnim { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
            property real bottomRAnim: bottomR
            Behavior on bottomRAnim { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }

            ShapePath {
                fillColor: rateRow.isCurrent
                           ? Qt.rgba(rateRow.accentColor.r, rateRow.accentColor.g, rateRow.accentColor.b, 0.12)
                           : (rateRow.isHovered
                              ? Qt.rgba(rateRow.accentColor.r, rateRow.accentColor.g, rateRow.accentColor.b, 0.1)
                              : Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.04))
                strokeColor: rateRow.isCurrent
                             ? Qt.rgba(rateRow.accentColor.r, rateRow.accentColor.g, rateRow.accentColor.b, 0.5)
                             : (rateRow.isHovered
                                ? Qt.rgba(rateRow.accentColor.r, rateRow.accentColor.g, rateRow.accentColor.b, 0.4)
                                : Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.15))
                strokeWidth: 1

                startX: rateBg.topRAnim + 1; startY: 1
                PathLine { x: rateBg.width - rateBg.topRAnim - 1; y: 1 }
                PathArc { x: rateBg.width - 1; y: rateBg.topRAnim + 1; radiusX: rateBg.topRAnim; radiusY: rateBg.topRAnim; direction: PathArc.Clockwise }
                PathLine { x: rateBg.width - 1; y: rateBg.height - rateBg.bottomRAnim - 1 }
                PathArc { x: rateBg.width - rateBg.bottomRAnim - 1; y: rateBg.height - 1; radiusX: rateBg.bottomRAnim; radiusY: rateBg.bottomRAnim; direction: PathArc.Clockwise }
                PathLine { x: rateBg.bottomRAnim + 1; y: rateBg.height - 1 }
                PathArc { x: 1; y: rateBg.height - rateBg.bottomRAnim - 1; radiusX: rateBg.bottomRAnim; radiusY: rateBg.bottomRAnim; direction: PathArc.Clockwise }
                PathLine { x: 1; y: rateBg.topRAnim + 1 }
                PathArc { x: rateBg.topRAnim + 1; y: 1; radiusX: rateBg.topRAnim; radiusY: rateBg.topRAnim; direction: PathArc.Clockwise }
            }
        }

        DankRipple {
            id: rateRipple
            anchors.fill: parent
            cornerRadius: rateBg.topRAnim
            rippleColor: rateRow.accentColor
        }

        RowLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Theme.spacingM
            anchors.rightMargin: Theme.spacingM
            spacing: Theme.spacingS

            DankIcon {
                name: rateRow.isCurrent ? "check_circle" : "radio_button_unchecked"
                size: 16
                color: rateRow.isCurrent ? rateRow.accentColor : Theme.surfaceVariantText
                opacity: rateRow.isCurrent ? 1.0 : 0.6
                Layout.alignment: Qt.AlignVCenter
            }

            DankSVGIcon {
                source: rateRow.iconSource
                size: 18
                colorOverride: rateRow.accentColor
                Layout.alignment: Qt.AlignVCenter
            }

            StyledText {
                text: rateRow.title
                font.pixelSize: Theme.fontSizeMedium
                font.weight: rateRow.isCurrent ? Font.Bold : Font.Medium
                color: Theme.surfaceText
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                elide: Text.ElideRight
            }

            ValueBadge {
                label: "C"
                value: rateRow.rate ? rateRow.rate.value_buy.toString() : "..."
                accentColor: rateRow.accentColor
                Layout.alignment: Qt.AlignVCenter
            }

            ValueBadge {
                label: "V"
                value: rateRow.rate ? rateRow.rate.value_sell.toString() : "..."
                accentColor: rateRow.accentColor
                Layout.alignment: Qt.AlignVCenter
            }
        }

        MouseArea {
            id: rateMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: rateRow.isCurrent ? Qt.ArrowCursor : Qt.PointingHandCursor
            onPressed: m => rateRipple.trigger(m.x, m.y)
            onClicked: {
                if (!rateRow.isCurrent)
                    PluginService.savePluginData("dolarBlue", "rateType", rateRow.rateKey);
            }
        }
    }

    popoutContent: Component {
        PopoutComponent {
            headerText: ""
            showCloseButton: false

            Item {
                width: parent.width
                height: mainCol.implicitHeight

                Column {
                    id: mainCol
                    width: parent.width
                    spacing: Theme.spacingM
                    topPadding: 0
                    bottomPadding: 2

                    // Header card
                    StyledRect {
                        width: parent.width
                        height: 72
                        radius: Theme.cornerRadius * 1.5
                        color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                        border.width: 1
                        border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.spacingM
                            anchors.right: headerRefreshBtn.left
                            anchors.rightMargin: Theme.spacingS
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacingM

                            Rectangle {
                                width: 42
                                height: 42
                                radius: 21
                                anchors.verticalCenter: parent.verticalCenter
                                color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)

                                DankSVGIcon {
                                    source: root.displayIconSource
                                    size: 22
                                    anchors.centerIn: parent
                                    colorOverride: root.hasError ? Theme.error : Theme.primary
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2
                                width: parent.width - 42 - Theme.spacingM

                                StyledText {
                                    width: parent.width
                                    text: root.displayTitle
                                    font.bold: true
                                    font.pixelSize: Theme.fontSizeLarge
                                    color: root.hasError ? Theme.error : Theme.surfaceText
                                    elide: Text.ElideRight
                                }

                                StyledText {
                                    width: parent.width
                                    text: root.lastUpdated
                                          ? ("Bluelytics • Updated " + root.formatHeaderTime(root.lastUpdated))
                                          : "Bluelytics"
                                    font.pixelSize: Theme.fontSizeSmall - 1
                                    color: Theme.primary
                                    opacity: 0.85
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        Rectangle {
                            id: headerRefreshBtn
                            anchors.right: parent.right
                            anchors.rightMargin: Theme.spacingM
                            anchors.verticalCenter: parent.verticalCenter
                            width: 38
                            height: 38
                            radius: Theme.cornerRadius
                            color: refreshMa.containsMouse
                                   ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
                                   : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08)
                            border.width: 1
                            border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, refreshMa.containsMouse ? 0.3 : 0.15)

                            scale: refreshMa.pressed ? 0.92 : (refreshMa.containsMouse ? 1.05 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                            Behavior on color { ColorAnimation { duration: 150 } }

                            DankRipple { id: refreshRipple; anchors.fill: parent; cornerRadius: Theme.cornerRadius; rippleColor: Theme.primary }

                            DankSpinner {
                                size: 20
                                color: Theme.primary
                                anchors.centerIn: parent
                                visible: root.loading
                            }

                            DankIcon {
                                name: "refresh"
                                size: 20
                                color: Theme.primary
                                anchors.centerIn: parent
                                visible: !root.loading

                                rotation: refreshMa.containsMouse ? 180 : 0
                                Behavior on rotation { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                            }

                            MouseArea {
                                id: refreshMa
                                anchors.fill: parent
                                hoverEnabled: !root.loading
                                cursorShape: Qt.PointingHandCursor
                                onPressed: m => refreshRipple.trigger(m.x, m.y)
                                onClicked: {
                                    root.manualRefresh = true;
                                    root.fetchData();
                                }
                            }
                        }
                    }

                    // Error card
                    StyledRect {
                        width: parent.width
                        visible: root.hasError && root.errorMessage.length > 0
                        height: Math.max(0, errText.implicitHeight + Theme.spacingM * 2)
                        radius: Theme.cornerRadius
                        color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12)
                        border.width: 1
                        border.color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.4)

                        StyledText {
                            id: errText
                            anchors.fill: parent
                            anchors.margins: Theme.spacingM
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            text: root.errorMessage
                            color: Theme.error
                            font.pixelSize: Theme.fontSizeSmall
                        }
                    }

                    // Rates card
                    StyledRect {
                        width: parent.width
                        height: Math.max(0, ratesCol.implicitHeight + Theme.spacingM * 2)
                        radius: Theme.cornerRadius
                        color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                        border.width: 1
                        border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)

                        Column {
                            id: ratesCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: Theme.spacingM
                            spacing: Theme.spacingS

                            RowLayout {
                                width: parent.width
                                spacing: Theme.spacingXS

                                DankIcon {
                                    name: "currency_exchange"
                                    size: 14
                                    color: Theme.surfaceText
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                StyledText {
                                    text: "Cotizaciones"
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Bold
                                    color: Theme.surfaceText
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                StyledText {
                                    text: "click para fijar en la barra"
                                    font.pixelSize: Theme.fontSizeSmall - 1
                                    color: Theme.surfaceVariantText
                                    opacity: 0.7
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }

                            Column {
                                width: parent.width
                                spacing: 4

                                RateRow {
                                    index: 0
                                    rateKey: "blue"
                                    title: "Dolar Blue"
                                    iconSource: Qt.resolvedUrl("dollar.svg")
                                    accentColor: Theme.primary
                                }

                                RateRow {
                                    index: 1
                                    rateKey: "oficial"
                                    title: "Dolar Oficial"
                                    iconSource: Qt.resolvedUrl("dollar.svg")
                                    accentColor: Theme.primary
                                }

                                RateRow {
                                    index: 2
                                    rateKey: "blue_euro"
                                    title: "Euro Blue"
                                    iconSource: Qt.resolvedUrl("euro.svg")
                                    accentColor: Theme.secondary
                                }

                                RateRow {
                                    index: 3
                                    rateKey: "oficial_euro"
                                    title: "Euro Oficial"
                                    iconSource: Qt.resolvedUrl("euro.svg")
                                    accentColor: Theme.secondary
                                }
                            }
                        }
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

                // Toast, shown only for a refresh the user asked for
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Theme.spacingS
                    height: 32
                    width: toastLayout.implicitWidth + Theme.spacingM * 2
                    radius: height / 2
                    color: Qt.rgba(Theme.surfaceContainerHighest.r, Theme.surfaceContainerHighest.g, Theme.surfaceContainerHighest.b, 0.95)
                    border.width: 1
                    border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.4)
                    z: 999
                    opacity: toastTimer.running ? 1.0 : 0.0
                    scale: toastTimer.running ? 1.0 : 0.75

                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                    RowLayout {
                        id: toastLayout
                        anchors.centerIn: parent
                        spacing: Theme.spacingXS

                        DankIcon { name: "info"; size: 16; color: Theme.primary }

                        StyledText {
                            text: root.toastText
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Bold
                            color: Theme.surfaceText
                        }
                    }
                }
            }
        }
    }


    popoutWidth: 420
    popoutHeight: 0
}
