import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "dolarBluePlugin"

    StyledText {
        width: parent.width
        text: "Configuración Dolar Blue"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Selecciona qué cotización deseas mostrar en el widget."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    SelectionSetting {
        settingKey: "rateType"
        label: "Tipo de Cambio"
        description: "Elige la cotización a visualizar"
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
        description: "How often to update the exchange rate (in minutes)."
        defaultValue: 10
        minimum: 1
        maximum: 60
        unit: "min"
        leftIcon: "schedule"
    }
}
