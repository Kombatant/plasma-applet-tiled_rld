import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import Qt.labs.platform as QtLabsPlatform

import ".." as TiledMenu
import "../libconfig" as LibConfig


LibConfig.FormKCM {
	id: formLayout

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
		// https://github.com/KDE/plasma-desktop/blob/master/desktoppackage/contents/configuration/AppletConfiguration.qml
		if (typeof root === "undefined") {
			return null
		}
		// [Plasma 5.15] root was the StackView { id: pageStack } in plasmoidviewer
		// [Plasma 5.15] However root was plasmashell is AppletConfiguration for some reason
		// [Plasma 5.15] The "root" id can't always be referenced here, so use one of the child id's and get it's parent.
		if (isClassName(root, 'AppletConfiguration')) {
			return root
		}
		// https://github.com/KDE/plasma-desktop/blob/master/desktoppackage/contents/configuration/ConfigurationAppletPage.qml
		// [Plasma 5.24] root is ConfigurationAppletPage. It does not have a parent when we check first check it so we need to
		//               wait until it is attached before looking for it's ancestor.
		// Walk up to the top node of the "DOM" for AppletConfiguration
		return getAncestor(root, 'AppletConfiguration')
	}
	property bool keyboardShortcutsHidden: false
	function hideKeyboardShortcutTab() {
		var appletConfiguration = getAppletConfiguration()
		if (appletConfiguration && typeof appletConfiguration.globalConfigModel !== "undefined") {
			// Remove default Global Keyboard Shortcut config tab.
			var keyboardShortcuts = appletConfiguration.globalConfigModel.get(0)
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
	//-------------------------------------------------------
	LibConfig.Heading {
		text: i18n("Panel Icon")
	}

	LibConfig.IconField {
		Layout.fillWidth: true
		configKey: 'icon'
		defaultValue: 'tiled_rld'
		previewIconSize: Kirigami.Units.iconSizes.large
		presetValues: [
			'format-border-set-none-symbolic',
			'applications-all-symbolic',
			'kde-symbolic',
			'openSUSE-distributor-logo',
			'choice-rhomb-symbolic',
			'choice-round-symbolic',
			'stateshape-symbolic',
			'beamerblock-symbolic',
		]
		showPresetLabel: false

		LibConfig.CheckBox {
			text: i18n("Fixed Size")
			configKey: 'fixedPanelIcon'
		}
	}

	//-------------------------------------------------------
	LibConfig.Heading {
		text: i18n("Tiles")
	}

	RowLayout {
		Kirigami.FormData.label: i18n("Tile Size")
		LibConfig.SpinBox {
			configKey: 'tileScale'
			suffix: 'x'
			minimumValue: 0.1
			maximumValue: 4
			decimals: 1
		}
		QQC2.Label {
			text: '' + config.cellBoxSize + i18n("px")
		}
	}
	RowLayout {
		Kirigami.FormData.label: i18n("Tile Icon Size")
		LibConfig.SpinBox {
			configKey: 'tileIconSize'
			suffix: i18n("px")
			minimumValue: 16
			maximumValue: 256
			decimals: 0
		}
		QQC2.Label {
			text: i18n("Base size for tile icons; small/large variants scale from this")
		}
	}
	LibConfig.SpinBox {
		configKey: 'tileMargin'
		Kirigami.FormData.label: i18n("Tile Margin")
		suffix: i18n("px")
		minimumValue: 0
		maximumValue: config.cellBoxUnits/2
	}

	LibConfig.RadioButtonGroup {
		id: tilesThemeGroup
		Kirigami.FormData.label: i18n("Background Color")
		Kirigami.FormData.buddyFor: defaultTileColorRadioButton
		spacing: 0 // "Custom Color" has lots of spacings already
		RowLayout {
			QQC2.RadioButton {
				id: defaultTileColorRadioButton
				text: i18n("Custom Color")
				QQC2.ButtonGroup.group: tilesThemeGroup.group
				checked: true
			}
			LibConfig.ColorField {
				id: defaultTileColorColor
				configKey: 'defaultTileColor'
			}
			LibConfig.CheckBox {
				text: i18n("Gradient")
				configKey: 'defaultTileGradient'
			}
		}
		QQC2.RadioButton {
			text: i18n("Transparent")
			QQC2.ButtonGroup.group: tilesThemeGroup.group
			onClicked: {
				defaultTileColorColor.text = "#00000000"
				defaultTileColorRadioButton.checked = true
			}
		}
	}
	LibConfig.ComboBox {
		configKey: "tileLabelAlignment"
		Kirigami.FormData.label: i18n("Text Alignment")
		model: [
			{ value: "left", text: i18n("Left") },
			{ value: "center", text: i18n("Center") },
			{ value: "right", text: i18n("Right") },
		]
	}
	LibConfig.ComboBox {
		configKey: "groupLabelAlignment"
		Kirigami.FormData.label: i18n("Group Text Alignment")
		model: [
			{ value: "left", text: i18n("Left") },
			{ value: "center", text: i18n("Center") },
			{ value: "right", text: i18n("Right") },
		]
	}
	RowLayout {
		id: presetTilesFolderRow
		Kirigami.FormData.label: i18n("Preset Tile Folder")
		Layout.fillWidth: true

		function pathToUrl(path) {
			var p = path || ""
			if (!p) {
				return ""
			}
			if (p.indexOf('://') !== -1) {
				return p
			}
			if (p.indexOf('~/') === 0) {
				var home = QtLabsPlatform.StandardPaths.writableLocation(QtLabsPlatform.StandardPaths.HomeLocation)
				if (home) {
					p = home + p.substr(1)
				}
			}
			if (p.indexOf('/') === 0) {
				return 'file://' + p
			}
			return p
		}

		function urlToPath(url) {
			if (!url) {
				return ''
			}
			var s = '' + url
			if (s.indexOf('file://') === 0) {
				s = s.substr('file://'.length)
			}
			return s
		}

		LibConfig.TextField {
			id: presetTilesFolderField
			Layout.fillWidth: true
			configKey: 'presetTilesFolder'
			placeholderText: config.defaultPresetTilesFolder
		}

		QQC2.Button {
			text: i18n("Browse...")
			icon.name: "folder-open"
			onClicked: {
				var startPath = presetTilesFolderField.text || config.defaultPresetTilesFolder
				presetTilesFolderDialog.currentFolder = presetTilesFolderRow.pathToUrl(startPath)
				presetTilesFolderDialog.open()
			}
		}

		QtLabsPlatform.FolderDialog {
			id: presetTilesFolderDialog
			title: i18n("Select Preset Tile Folder")
			onAccepted: {
				var folderPath = presetTilesFolderRow.urlToPath(currentFolder)
				if (folderPath) {
					presetTilesFolderField.text = folderPath
				}
			}
		}
	}

}
