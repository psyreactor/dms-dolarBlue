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

    property string displayIcon: {
        if (rateType.indexOf("euro") !== -1) return "euro_symbol";
        return "attach_money";
    }

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
                            root.lastUpdate = new Date().toLocaleTimeString();
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
            DankIcon {
                name: root.displayIcon
                size: Theme.iconSize - 4
                anchors.verticalCenter: parent.verticalCenter
            }
            StyledText {
                text: root.loading ? "..." : "C: $" + root.buyValue
                anchors.verticalCenter: parent.verticalCenter
            }
            StyledText {
                text: "|"
                color: Theme.onSurfaceVariant
                anchors.verticalCenter: parent.verticalCenter
            }
            StyledText {
                text: root.loading ? "..." : "V: $" + root.sellValue
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: 2
            DankIcon {
                name: root.displayIcon
                size: 24
                anchors.horizontalCenter: parent.horizontalCenter
            }
            StyledText {
                text: root.loading ? "..." : "$" + root.buyValue
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: Theme.fontSizeMedium
            }
            StyledText {
                text: root.loading ? "..." : "$" + root.sellValue
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: Theme.fontSizeMedium
            }
        }
    }

    component RateRow: Row {
        property string title
        property string buy
        property string sell
        property string iconName: "attach_money"
        
        spacing: Theme.spacingL
        anchors.horizontalCenter: parent.horizontalCenter

        Row {
            spacing: Theme.spacingS
            width: 150
            DankIcon {
                name: iconName
                size: 24
                color: Theme.primary
                anchors.verticalCenter: parent.verticalCenter
            }
            StyledText {
                text: title
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Column {
            width: 100
            StyledText {
                text: "Compra"
                font.pixelSize: Theme.fontSizeSmall
                anchors.horizontalCenter: parent.horizontalCenter
            }
            StyledText {
                text: "$" + buy
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        Column {
            width: 100
            StyledText {
                text: "Venta"
                font.pixelSize: Theme.fontSizeSmall
                anchors.horizontalCenter: parent.horizontalCenter
            }
            StyledText {
                text: "$" + sell
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    popoutContent: Component {
            Column {
                anchors.fill: parent
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingL
                
                // Header
                Row {
                    width: parent.width
                    spacing: Theme.spacingM
                    
                    StyledText {
                        text: "Cotizaciones"
                        font.bold: true
                        font.pixelSize: Theme.fontSizeLarge
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                
                // Rates
                Column {
                    width: parent.width
                    spacing: Theme.spacingL
                    
                    RateRow {
                        title: "Dolar Blue"
                        buy: root.allRates.blue ? root.allRates.blue.value_buy : "..."
                        sell: root.allRates.blue ? root.allRates.blue.value_sell : "..."
                    }
                    
                    RateRow {
                        title: "Dolar Oficial"
                        buy: root.allRates.oficial ? root.allRates.oficial.value_buy : "..."
                        sell: root.allRates.oficial ? root.allRates.oficial.value_sell : "..."
                    }

                    RateRow {
                        title: "Euro Blue"
                        iconName: "euro_symbol"
                        buy: root.allRates.blue_euro ? root.allRates.blue_euro.value_buy : "..."
                        sell: root.allRates.blue_euro ? root.allRates.blue_euro.value_sell : "..."
                    }

                    RateRow {
                        title: "Euro Oficial"
                        iconName: "euro_symbol"
                        buy: root.allRates.oficial_euro ? root.allRates.oficial_euro.value_buy : "..."
                        sell: root.allRates.oficial_euro ? root.allRates.oficial_euro.value_sell : "..."
                    }
                }

                // Custom Buttons
                Row {
                    visible: (root.buttonText && root.buttonUrl) || (root.buttonText2 && root.buttonUrl2)
                    width: parent.width
                    height: visible ? 48 : 0
                    spacing: Theme.spacingM

                    // First Button
                    Rectangle {
                        visible: root.buttonText && root.buttonUrl
                        width: root.buttonText2 && root.buttonUrl2 ? (parent.width - Theme.spacingM) / 2 : parent.width
                        height: 48
                        radius: Theme.cornerRadius
                        color: buttonMouse1.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
                        border.width: 0

                        Row {
                            anchors.centerIn: parent
                            spacing: Theme.spacingS

                            DankIcon {
                                name: "open_in_new"
                                size: 20
                                color: Theme.primary
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: root.buttonText
                                font.pixelSize: Theme.fontSizeMedium
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
                        height: 48
                        radius: Theme.cornerRadius
                        color: buttonMouse2.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
                        border.width: 0

                        Row {
                            anchors.centerIn: parent
                            spacing: Theme.spacingS

                            DankIcon {
                                name: "open_in_new"
                                size: 20
                                color: Theme.primary
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: root.buttonText2
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.primary
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

    popoutWidth: 450
    popoutHeight: (root.buttonText && root.buttonUrl) || (root.buttonText2 && root.buttonUrl2) ? 320 : 260
}