import QtQuick
import org.kde.plasma.configuration

ConfigModel {
	ConfigCategory {
		name: i18n("General")
		icon: "configure"
		source: "config/ConfigGeneral.qml"
	}
	ConfigCategory {
		name: i18n("Sidebar")
		icon: "sidebar-expand-left"
		source: "config/ConfigSidebar.qml"
	}
	ConfigCategory {
		name: i18n("Search")
		icon: "edit-find"
		source: "config/ConfigSearch.qml"
	}
	ConfigCategory {
		name: i18n("Import/Export Layout")
		icon: "grid-rectangular"
		source: "config/ConfigExportLayout.qml"
	}
	ConfigCategory {
		name: i18n("Advanced")
		icon: "applications-development"
		source: "lib/ConfigAdvanced.qml"
		visible: false
	}
	ConfigCategory {
		name: i18nd("plasma_shell_org.kde.plasma.desktop", "Keyboard Shortcuts")
		icon: "preferences-desktop-keyboard"
		source: "config/ConfigurationShortcuts.qml"
	}
}
