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
        description: "Intervalo de actualización del contexto (en segundos)."
        defaultValue: 15
        minimum: 10
        maximum: 600
        unit: "seg"
        leftIcon: "schedule"
    }

    StringSetting {
        settingKey: "buttonText"
        label: "Button Text"
        description: "Text to display on the button in the popup (leave empty to hide button)."
        defaultValue: "Dolar Hoy"
        placeholder: "e.g., Ver más información"
    }

    StringSetting {
        settingKey: "buttonUrl"
        label: "Button URL"
        description: "URL to open when clicking the button (e.g., https://dolarhoy.com)."
        defaultValue: "https://dolarhoy.com"
        placeholder: "https://example.com"
    }

    StringSetting {
        settingKey: "buttonText2"
        label: "Button 2 Text"
        description: "Text to display on the second button in the popup (leave empty to hide button)."
        defaultValue: "Dolarito"
        placeholder: "e.g., Ver más información"
    }

    StringSetting {
        settingKey: "buttonUrl2"
        label: "Button 2 URL"
        description: "URL to open when clicking the second button (e.g., https://dolarhoy.com)."
        defaultValue: "https://dolarito.ar"
        placeholder: "https://example.com"
    }
}
