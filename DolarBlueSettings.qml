import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "dolarBlue"

    // Section header: icon, title and a one-line explanation of the group.
    component GroupHeader: RowLayout {
        property string iconName: ""
        property string title: ""
        property string subtitle: ""

        width: parent.width
        spacing: Theme.spacingM

        DankIcon {
            name: iconName
            size: 22
            color: Theme.primary
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                text: title
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
                Layout.fillWidth: true
            }

            StyledText {
                text: subtitle
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }
    }

    // Card wrapper matching the popout's cards.
    component SettingsGroup: StyledRect {
        default property alias content: groupCol.data

        width: parent.width
        height: Math.max(0, groupCol.implicitHeight + Theme.spacingM * 2)
        radius: Theme.cornerRadius
        color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
        border.width: 1
        border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)

        Column {
            id: groupCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.spacingM
            spacing: Theme.spacingL
        }
    }

    Column {
        width: parent.width
        spacing: Theme.spacingL

        SettingsGroup {
            GroupHeader {
                iconName: "currency_exchange"
                title: "Cotización"
                subtitle: "Cuál se muestra en la barra. También se puede fijar clickeándola en el popout."
            }

            SelectionSetting {
                settingKey: "rateType"
                label: "Tipo de Cambio"
                description: "Elige la cotización a visualizar."
                options: [
                    {label: "Dolar Blue", value: "blue"},
                    {label: "Dolar Oficial", value: "oficial"},
                    {label: "Euro Blue", value: "blue_euro"},
                    {label: "Euro Oficial", value: "oficial_euro"}
                ]
                defaultValue: "blue"
            }

            SliderSetting {
                settingKey: "refreshInterval"
                label: "Refresh Interval"
                description: "Frecuencia de actualización contra bluelytics, en minutos."
                defaultValue: 10
                minimum: 1
                maximum: 60
                unit: "min"
                leftIcon: "schedule"
            }
        }

        SettingsGroup {
            GroupHeader {
                iconName: "link"
                title: "Enlaces"
                subtitle: "Dos accesos directos al pie del popout. Dejá el texto vacío para ocultar uno."
            }

            StringSetting {
                settingKey: "buttonText"
                label: "Button Text"
                description: "Texto del primer botón."
                defaultValue: "Dolar Hoy"
                placeholder: "Dolar Hoy"
            }

            StringSetting {
                settingKey: "buttonUrl"
                label: "Button URL"
                description: "URL que abre el primer botón."
                defaultValue: "https://dolarhoy.com"
                placeholder: "https://dolarhoy.com"
            }

            StringSetting {
                settingKey: "buttonText2"
                label: "Button 2 Text"
                description: "Texto del segundo botón."
                defaultValue: "Dolarito"
                placeholder: "Dolarito"
            }

            StringSetting {
                settingKey: "buttonUrl2"
                label: "Button 2 URL"
                description: "URL que abre el segundo botón."
                defaultValue: "https://dolarito.ar"
                placeholder: "https://dolarito.ar"
            }
        }

        SettingsGroup {
            GroupHeader {
                iconName: "schedule"
                title: "Display"
                subtitle: "Cómo se muestra la hora en el encabezado del popout."
            }

            SelectionSetting {
                settingKey: "timeFormat"
                label: "Time Format"
                description: "Formato del indicador de última actualización."
                options: [
                    {label: "System Default", value: "system"},
                    {label: "12-Hour", value: "12h"},
                    {label: "24-Hour", value: "24h"}
                ]
                defaultValue: "system"
            }
        }
    }
}
