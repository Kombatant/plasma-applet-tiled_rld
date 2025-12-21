import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore

import ".." as TiledMenu

ColumnLayout {
	id: page

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
