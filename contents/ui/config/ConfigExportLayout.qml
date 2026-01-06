import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami
import Qt.labs.platform as QtLabsPlatform

import ".." as TiledMenu

ColumnLayout {
	id: page
	spacing: Kirigami.Units.smallSpacing

	Component.onCompleted: {
		// Populate the export text area with the current settings on first open.
		// (Without this, the page can appear blank until the user imports.)
		if (exportData && typeof exportData.setValue === "function" && typeof exportData.buildNestedExportObject === "function") {
			exportData.setValue(exportData.buildNestedExportObject())
		}
	}

	function _shellSingleQuote(s) {
		s = (typeof s === "undefined" || s === null) ? "" : ("" + s)
		// POSIX shell single-quote escape: close, insert \' , reopen.
		return "'" + s.replace(/'/g, "'\\''") + "'"
	}

	function _toLocalPath(urlOrString) {
		var s = (typeof urlOrString === "undefined" || urlOrString === null) ? "" : ("" + urlOrString)
		if (!s) {
			return ""
		}
		// Qt.labs.platform FileDialog returns a file:// URL.
		if (s.indexOf("file://") === 0) {
			s = s.substring("file://".length)
			// file:///home/... => /home/...
			if (s.length >= 2 && s.charAt(0) === '/' && s.charAt(1) === '/') {
				s = s.substring(1)
			}
			try {
				s = decodeURIComponent(s)
			} catch (e) {
				// ignore
			}
		}
		return s
	}

	Plasma5Support.DataSource {
		id: exec
		engine: "executable"
		connectedSources: []
		onNewData: function(sourceName, data) {
			// One-shot command execution.
			disconnectSource(sourceName)
			var exitCode = data && typeof data["exit code"] !== "undefined" ? data["exit code"] : 0
			if (exitCode && exitCode !== 0) {
				var stderr = data && data.stderr ? ("" + data.stderr).trim() : ""
				var msg = stderr ? stderr : i18n("Failed to save file")
				if (typeof showPassiveNotification === "function") {
					showPassiveNotification(msg)
				}
			}
		}
	}

	Plasma5Support.DataSource {
		id: execRead
		engine: "executable"
		connectedSources: []
		property string pendingImportPath: ""
		onNewData: function(sourceName, data) {
			disconnectSource(sourceName)
			var exitCode = data && typeof data["exit code"] !== "undefined" ? data["exit code"] : 0
			if (exitCode && exitCode !== 0) {
				var stderr = data && data.stderr ? ("" + data.stderr).trim() : ""
				var msg = stderr ? stderr : i18n("Failed to import file")
				if (typeof showPassiveNotification === "function") {
					showPassiveNotification(msg)
				}
				return
			}
			var out = data && data.stdout ? ("" + data.stdout).trim() : ""
			if (!out) {
				if (typeof showPassiveNotification === "function") {
					showPassiveNotification(i18n("Import produced no data"))
				}
				return
			}
			var text = ""
			try {
				text = Qt.atob(out)
			} catch (e) {
				if (typeof showPassiveNotification === "function") {
					showPassiveNotification(i18n("Failed to decode imported file"))
				}
				return
			}
			try {
				exportData.textArea.text = text
				exportData.serialize()
				if (typeof showPassiveNotification === "function") {
					showPassiveNotification(i18n("Imported from %1", pendingImportPath || ""))
				}
			} catch (e2) {
				if (typeof showPassiveNotification === "function") {
					showPassiveNotification(i18n("Failed to import settings"))
				}
			}
		}
	}

	QtLabsPlatform.FileDialog {
		id: saveDialog
		title: i18n("Save Layout")
		fileMode: QtLabsPlatform.FileDialog.SaveFile
		nameFilters: [
			i18n("Layout Files (*.xml)"),
			i18n("All Files (*)"),
		]
		defaultSuffix: "xml"
		onAccepted: {
			var chosenUrl = (saveDialog.currentFile || saveDialog.file || saveDialog.selectedFile || (saveDialog.files && saveDialog.files.length ? saveDialog.files[0] : ""))
			var filePath = page._toLocalPath(chosenUrl)
			if (!filePath) {
				return
			}
			page.saveExportToFilePath(filePath)
		}
	}

	QtLabsPlatform.FileDialog {
		id: importDialog
		title: i18n("Import Layout")
		fileMode: QtLabsPlatform.FileDialog.OpenFile
		nameFilters: [
			i18n("Layout Files (*.xml)"),
			i18n("All Files (*)"),
		]
		onAccepted: {
			var chosenUrl = (importDialog.currentFile || importDialog.file || importDialog.selectedFile || (importDialog.files && importDialog.files.length ? importDialog.files[0] : ""))
			var filePath = page._toLocalPath(chosenUrl)
			if (!filePath) {
				return
			}
			page.importFromFilePath(filePath)
		}
	}

	function saveExportToFilePath(filePath) {
		var text = exportData && typeof exportData.textAreaText !== "undefined" ? ("" + exportData.textAreaText) : ""
		var b64 = Qt.btoa(text)
		// Use python for the actual write to avoid shell/base64 utility dependencies.
		var py = "import sys,base64,pathlib; pathlib.Path(sys.argv[1]).write_bytes(base64.b64decode(sys.argv[2].encode('ascii')))"
		var cmd = "python3 -c " + _shellSingleQuote(py) + " " + _shellSingleQuote(filePath) + " " + _shellSingleQuote(b64)
		exec.connectSource(cmd)
		if (typeof showPassiveNotification === "function") {
			showPassiveNotification(i18n("Saved to %1", filePath))
		}
	}

	function importFromFilePath(filePath) {
		execRead.pendingImportPath = filePath
		// Read bytes then base64 to stdout so QML can safely receive the content.
		var py = "import sys,base64; sys.stdout.write(base64.b64encode(open(sys.argv[1],'rb').read()).decode('ascii'))"
		var cmd = "python3 -c " + _shellSingleQuote(py) + " " + _shellSingleQuote(filePath)
		execRead.connectSource(cmd)
	}

	RowLayout {
		Layout.fillWidth: true
		spacing: Kirigami.Units.smallSpacing
		Item { Layout.fillWidth: true }
		Button {
			text: i18n("Import XML")
			icon.name: "document-open"
			onClicked: {
				importDialog.open()
			}
		}
		Button {
			text: i18n("Export XML")
			icon.name: "document-save"
			onClicked: {
				saveDialog.open()
			}
		}
	}

	ScrollView {
		Layout.fillWidth: true
		Layout.fillHeight: true
		clip: true

		TextAreaBase64JsonString {
			id: exportData
			anchors.fill: parent
	
			TiledMenu.Base64JsonString {
				id: configTileModel
				configKey: 'tileModel'
				writing: exportData.base64JsonString.writing
				defaultValue: []
			}

			property var ignoredKeys: [
				// Export/import all configuration keys so new settings remain in sync.
			]

			function buildFlatConfigObject() {
				var data = {}
				var configKeyList = plasmoid.configuration.keys()
				for (var i = 0; i < configKeyList.length; i++) {
					var configKey = configKeyList[i]
					var configValue = plasmoid.configuration[configKey]
					if (typeof configValue === "undefined") {
						continue
					}
					// Filter KF5 5.78 default keys https://invent.kde.org/frameworks/kdeclarative/-/merge_requests/38
					if (configKey.endsWith('Default')) {
						var key2 = configKey.substr(0, configKey.length - 'Default'.length)
						if (typeof plasmoid.configuration[key2] !== 'undefined') {
							continue
						}
					}
					if (configKey == 'tileModel') {
						data.tileModel = configTileModel.value
					} else {
						data[configKey] = configValue
					}
				}
				return data
			}

			function sectionForKey(configKey) {
				if (configKey.startsWith('tile') || configKey === 'tilesLocked' || configKey === 'favGridCols' || configKey.startsWith('defaultTile')) {
					return 'Tiles'
				}
				if (configKey.startsWith('sidebar')) {
					return 'Sidebar'
				}
				if (configKey.startsWith('search') || configKey === 'hideSearchField') {
					return 'Search'
				}
				if (configKey.startsWith('appList') || configKey === 'appDescription' || configKey === 'defaultAppListView' || configKey === 'showRecentApps' || configKey === 'recentOrdering' || configKey === 'numRecentApps') {
					return 'Application List'
				}
				if (configKey === 'popupHeight' || configKey === 'icon' || configKey === 'fixedPanelIcon' || configKey === 'terminalApp' || configKey === 'taskManagerApp' || configKey === 'fileManagerApp' || configKey === 'presetTilesFolder') {
					return 'General'
				}
				return 'Other'
			}

			function sortObjectKeys(obj) {
				var keys = Object.keys(obj)
				keys.sort()
				var out = {}
				for (var i = 0; i < keys.length; i++) {
					var k = keys[i]
					out[k] = obj[k]
				}
				return out
			}

			function buildNestedExportObject() {
				var flat = buildFlatConfigObject()
				var grouped = {
					'General': {},
					'Application List': {},
					'Search': {},
					'Sidebar': {},
					'Tiles': {},
					'Other': {},
				}

				var keys = Object.keys(flat)
				for (var i = 0; i < keys.length; i++) {
					var configKey = keys[i]
					var section = sectionForKey(configKey)
					grouped[section][configKey] = flat[configKey]
				}

				return {
					_meta: {
						format: 'tiled_rld',
						version: 1,
					},
					'General': sortObjectKeys(grouped['General']),
					'Application List': sortObjectKeys(grouped['Application List']),
					'Search': sortObjectKeys(grouped['Search']),
					'Sidebar': sortObjectKeys(grouped['Sidebar']),
					'Tiles': sortObjectKeys(grouped['Tiles']),
					'Other': sortObjectKeys(grouped['Other']),
				}
			}
			
			defaultValue: {
				return buildNestedExportObject()
			}

			function flattenImportedObject(imported, configKeyList) {
				if (!imported || typeof imported !== 'object') {
					return {}
				}

				// Nested format: merge all sections into a flat map.
				var flat = {}
				for (var sectionName in imported) {
					if (sectionName === '_meta') {
						continue
					}
					var sectionObj = imported[sectionName]
					if (!sectionObj || typeof sectionObj !== 'object' || Array.isArray(sectionObj)) {
						continue
					}
					for (var key in sectionObj) {
						if (typeof sectionObj[key] !== 'undefined') {
							flat[key] = sectionObj[key]
						}
					}
				}
				return flat
			}

			function serialize() {
				var imported = parseText(textArea.text)
				var configKeyList = plasmoid.configuration.keys()
				var newValue = flattenImportedObject(imported, configKeyList)
				for (var i = 0; i < configKeyList.length; i++) {
					var configKey = configKeyList[i]
					var propValue = newValue[configKey]
					if (typeof propValue === "undefined") {
						continue
					}
					// No ignored keys
					if (configKey == 'tileModel') {
						configTileModel.set(propValue)
					} else {
						if (plasmoid.configuration[configKey] != propValue) {
							plasmoid.configuration[configKey] = propValue
						}
					}
				}
			}
		}
	}

}
