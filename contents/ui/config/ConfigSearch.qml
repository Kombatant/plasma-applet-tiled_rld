import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore

import ".." as TiledMenu
import "../libconfig" as LibConfig


LibConfig.FormKCM {
	id: formLayout
	readonly property bool searchFieldHidden: !!plasmoid.configuration.hideSearchField
	readonly property bool searchOptionsEnabled: !searchFieldHidden

	readonly property string plasmaStyleLabelText: {
		var plasmaStyleText = i18nd("kcm_desktoptheme", "Plasma Style")
		return plasmaStyleText + ' (' + PlasmaCore.Theme.themeName + ')'
	}

	function isClassName(item, className) {
		var itemClassName = (''+item).split('_', 1)[0]
		return itemClassName == className
	}
	function getAncestor(item, className) {
		var curItem = item
		while (curItem.parent) {
			curItem = curItem.parent
			if (isClassName(curItem, className)) {
				return curItem
			}
		}
		return null
	}
	function getAppletConfiguration() {
		if (typeof root === "undefined") {
			return null
		}
		if (isClassName(root, 'AppletConfiguration')) {
			return root
		}
		return getAncestor(root, 'AppletConfiguration')
	}
	property bool keyboardShortcutsHidden: false
	function hideKeyboardShortcutTab() {
		var appletConfiguration = getAppletConfiguration()
		if (appletConfiguration && typeof appletConfiguration.globalConfigModel !== "undefined") {
			appletConfiguration.globalConfigModel.removeCategoryAt(0)
			keyboardShortcutsHidden = true
		}
	}

	Component.onCompleted: {
		hideKeyboardShortcutTab()

		if (typeof root !== "undefined" && isClassName(root, 'ConfigurationAppletPage')) {
			root.parentChanged.connect(function(){
				hideKeyboardShortcutTab()
			})
		}
	}

	property var config: TiledMenu.AppletConfig {
		id: config
	}

	//-------------------------------------------------------
	LibConfig.Heading {
		text: i18n("Search Box")
	}

	LibConfig.CheckBox {
		configKey: 'hideSearchField'
		text: i18n("Hide Search Field")
	}

	LibConfig.CheckBox {
		configKey: 'searchOnTop'
		text: i18n("Search On Top")
		enabled: formLayout.searchOptionsEnabled
		opacity: enabled ? 1 : 0.45
	}

	LibConfig.SpinBox {
		configKey: 'searchFieldHeight'
		Kirigami.FormData.label: i18n("Search Field Height")
		suffix: i18n("px")
		minimumValue: 0
		enabled: formLayout.searchOptionsEnabled
		opacity: enabled ? 1 : 0.45
	}

	LibConfig.RadioButtonGroup {
		Kirigami.FormData.label: i18n("Search Box Theme")
		enabled: formLayout.searchOptionsEnabled
		opacity: enabled ? 1 : 0.45
		QQC2.RadioButton {
			text: plasmaStyleLabelText
			checked: plasmoid.configuration.searchFieldFollowsTheme
			onClicked: plasmoid.configuration.searchFieldFollowsTheme = true
		}
		QQC2.RadioButton {
			text: i18n("Windows (White)")
			checked: !plasmoid.configuration.searchFieldFollowsTheme
			onClicked: plasmoid.configuration.searchFieldFollowsTheme = false
		}
	}

	LibConfig.CheckBox {
		configKey: 'searchResultsGrouped'
		text: i18n("Group search results")
		enabled: formLayout.searchOptionsEnabled
		opacity: enabled ? 1 : 0.45
	}

	// For debugging purposes.
	// User can configures the Filters in the SearchView
	// LibConfig.TextAreaStringList {
	// 	Kirigami.FormData.label: i18n("Search Plugins")
	// 	configKey: 'searchDefaultFilters'
	// 	readOnly: true
	// 	function serialize() {
	// 		// Do nothing
	// 	}
	// }
}
