import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.plasmoid

KCM.SimpleKCM {
	id: page

	// Plasma's config dialog tries to set `cfg_<key>` and `cfg_<key>Default` properties
	// on the root item. We write directly to `plasmoid.configuration` in our pages, but
	// defining these avoids noisy "Setting initial properties failed" warnings.
	property var cfg_icon
	property var cfg_iconDefault
	property var cfg_fixedPanelIcon
	property var cfg_fixedPanelIconDefault
	property var cfg_searchResultsGrouped
	property var cfg_searchResultsGroupedDefault
	property var cfg_searchDefaultFilters
	property var cfg_searchDefaultFiltersDefault
	property var cfg_showRecentApps
	property var cfg_showRecentAppsDefault
	property var cfg_recentOrdering
	property var cfg_recentOrderingDefault
	property var cfg_numRecentApps
	property var cfg_numRecentAppsDefault
	property var cfg_sidebarShortcuts
	property var cfg_sidebarShortcutsDefault
	property var cfg_defaultAppListView
	property var cfg_defaultAppListViewDefault
	property var cfg_terminalApp
	property var cfg_terminalAppDefault
	property var cfg_taskManagerApp
	property var cfg_taskManagerAppDefault
	property var cfg_fileManagerApp
	property var cfg_fileManagerAppDefault
	property var cfg_tileModel
	property var cfg_tileModelDefault
	property var cfg_tileScale
	property var cfg_tileScaleDefault
	property var cfg_tileIconSize
	property var cfg_tileIconSizeDefault
	property var cfg_tileMargin
	property var cfg_tileMarginDefault
	property var cfg_tilesLocked
	property var cfg_tilesLockedDefault
	property var cfg_defaultTileColor
	property var cfg_defaultTileColorDefault
	property var cfg_defaultTileGradient
	property var cfg_defaultTileGradientDefault
	property var cfg_sidebarBackgroundColor
	property var cfg_sidebarBackgroundColorDefault
	property var cfg_hideSearchField
	property var cfg_hideSearchFieldDefault
	property var cfg_searchOnTop
	property var cfg_searchOnTopDefault
	property var cfg_searchFieldFollowsTheme
	property var cfg_searchFieldFollowsThemeDefault
	property var cfg_sidebarFollowsTheme
	property var cfg_sidebarFollowsThemeDefault
	property var cfg_tileLabelAlignment
	property var cfg_tileLabelAlignmentDefault
	property var cfg_groupLabelAlignment
	property var cfg_groupLabelAlignmentDefault
	property var cfg_showGroupTileNameBorder
	property var cfg_showGroupTileNameBorderDefault
	property var cfg_presetTilesFolder
	property var cfg_presetTilesFolderDefault
	property var cfg_appDescription
	property var cfg_appDescriptionDefault
	property var cfg_appListIconSize
	property var cfg_appListIconSizeDefault
	property var cfg_searchFieldHeight
	property var cfg_searchFieldHeightDefault
	property var cfg_appListWidth
	property var cfg_appListWidthDefault
	property var cfg_popupHeight
	property var cfg_popupHeightDefault
	property var cfg_favGridCols
	property var cfg_favGridColsDefault
	property var cfg_sidebarButtonSize
	property var cfg_sidebarButtonSizeDefault
	property var cfg_sidebarIconSize
	property var cfg_sidebarIconSizeDefault
	property var cfg_sidebarViewLabels
	property var cfg_sidebarViewLabelsDefault
	property var cfg_sidebarPopupButtonSize
	property var cfg_sidebarPopupButtonSizeDefault

	// Kate-like: sidebar search + section list + page content.
	title: i18n("Settings")

	// Make the initial config window a bit wider so pages lay out cleanly.
	// Do not force shrink: respect user resizing after open.
	readonly property int wideModeMinWidth: Kirigami.Units.gridUnit * 40
	readonly property int preferredWindowWidth: Kirigami.Units.gridUnit * 48
	function _applyWindowWidthConstraints() {
		if (!Window.window || !Window.window.visible) {
			return
		}
		if (Window.window.width < wideModeMinWidth) {
			Window.window.width = wideModeMinWidth
		}
		if (Window.window.width < preferredWindowWidth) {
			Window.window.width = preferredWindowWidth
		}
	}
	Window.onWindowChanged: {
		if (Window.window) {
			Window.window.visibleChanged.connect(function() {
				// Defer: Plasma applies its own initial sizing during show.
				_applyWindowWidthConstraints()
				Qt.callLater(_applyWindowWidthConstraints)
			})
		}
	}

	property string filterText: ""
	property string currentSectionKey: ""

	readonly property var _allSections: [
		{
			key: "general",
			name: i18n("General"),
			icon: "configure",
			source: "ConfigGeneral.qml",
			visible: true,
		},
		{
			key: "sidebar",
			name: i18n("Sidebar"),
			icon: "sidebar-expand-left",
			source: "ConfigSidebar.qml",
			visible: true,
		},
		{
			key: "search",
			name: i18n("Search"),
			icon: "edit-find",
			source: "ConfigSearch.qml",
			visible: true,
		},
		{
			key: "layout",
			name: i18n("Import/Export Layout"),
			icon: "grid-rectangular",
			source: "ConfigExportLayout.qml",
			visible: true,
		},
		{
			key: "advanced",
			name: i18n("Advanced"),
			icon: "applications-development",
			source: "../lib/ConfigAdvanced.qml",
			// Keep parity with prior behavior: hidden by default.
			visible: false,
		},
		{
			key: "shortcuts",
			name: i18nd("plasma_shell_org.kde.plasma.desktop", "Keyboard Shortcuts"),
			icon: "preferences-desktop-keyboard",
			source: "SectionKeyboardShortcuts.qml",
			visible: true,
		},
		{
			key: "about",
			name: i18n("About"),
			icon: "help-about",
			source: "SectionAbout.qml",
			visible: true,
		},
	]

	readonly property var filteredSections: {
		var needle = (filterText || "").trim().toLowerCase()
		var out = []
		for (var i = 0; i < _allSections.length; i++) {
			var s = _allSections[i]
			if (!s || !s.visible) {
				continue
			}
			if (!needle || (s.name || "").toLowerCase().indexOf(needle) !== -1) {
				out.push(s)
			}
		}
		return out
	}

	function _sectionByKey(key) {
		for (var i = 0; i < _allSections.length; i++) {
			var s = _allSections[i]
			if (s && s.key === key) {
				return s
			}
		}
		return null
	}

	function _ensureValidSelection() {
		// Keep the current selection when possible; otherwise select the first item.
		for (var i = 0; i < filteredSections.length; i++) {
			if (filteredSections[i].key === currentSectionKey) {
				return
			}
		}
		currentSectionKey = filteredSections.length ? filteredSections[0].key : ""
	}

	onFilterTextChanged: _ensureValidSelection()
	Component.onCompleted: {
		_startCollapseOuterNavigation()
		_ensureValidSelection()
		_shortcutPending = ("" + Plasmoid.globalShortcut)
		_applyWindowWidthConstraints()

		// On some Plasma versions, the config page attaches late.
		// Retry once root gets a parent.
		if (typeof root !== "undefined" && root && typeof root.parentChanged === "function") {
			root.parentChanged.connect(function() {
				_startCollapseOuterNavigation()
				_applyWindowWidthConstraints()
			})
		}
	}

	Timer {
		id: collapseOuterNavRetry
		interval: 50
		repeat: true
		property int attemptsLeft: 20
		onTriggered: {
			var collapsed = page._collapseOuterNavigationOnce()
			var applyHidden = page._hideHostApplyButtonOnce()
			if (collapsed && applyHidden) {
				stop()
				return
			}
			attemptsLeft -= 1
			if (attemptsLeft <= 0) {
				stop()
			}
		}
	}

	function _startCollapseOuterNavigation() {
		collapseOuterNavRetry.attemptsLeft = 20
		collapseOuterNavRetry.restart()
	}

	// --- Keyboard shortcuts: preserve Apply/OK semantics.
	property string _shortcutPending: ""
	signal configurationChanged()
	function saveConfig() {
		// Called by the config dialog on Apply/OK.
		if (("" + Plasmoid.globalShortcut) !== ("" + _shortcutPending)) {
			Plasmoid.globalShortcut = _shortcutPending
		}
	}

	function _walk(item, maxDepth, visitor) {
		if (!item || maxDepth < 0) {
			return false
		}
		if (visitor(item)) {
			return true
		}
		var kids = item.children
		if (!kids || kids.length === 0) {
			return false
		}
		for (var i = 0; i < kids.length; i++) {
			if (_walk(kids[i], maxDepth - 1, visitor)) {
				return true
			}
		}
		return false
	}

	function _findFirst(item, maxDepth, predicate) {
		var found = null
		_walk(item, maxDepth, function(node) {
			if (predicate(node)) {
				found = node
				return true
			}
			return false
		})
		return found
	}

	function _collapseOuterNavigationOnce() {
		// The outer strip is hard-coded by Plasma's AppletConfiguration.qml.
		// We collapse it so our inner Kate-like sidebar is the only navigation.
		function isClassName(item, className) {
			var itemClassName = ("" + item).split("_", 1)[0]
			return itemClassName === className
		}
		function getAncestor(item, className) {
			var curItem = item
			while (curItem && curItem.parent) {
				curItem = curItem.parent
				if (isClassName(curItem, className)) {
					return curItem
				}
			}
			return null
		}

		if (typeof root === "undefined" || !root) {
			return false
		}
		var appletConfiguration = isClassName(root, "AppletConfiguration") ? root : getAncestor(root, "AppletConfiguration")
		if (!appletConfiguration) {
			return false
		}

		// Find the outer category strip (a QQC2.ScrollView with fixed width = gridUnit*7).
		var expectedWidth = Kirigami.Units.gridUnit * 7
		var categoriesStrip = _findFirst(appletConfiguration, 4, function(node) {
			if (!node || typeof node.width === "undefined") {
				return false
			}
			var isScroll = ("" + node).indexOf("ScrollView") !== -1
			if (!isScroll) {
				return false
			}
			return Math.abs(node.width - expectedWidth) <= 2
		})

		// Find the Kirigami.ApplicationItem that hosts the page stack.
		var appItem = _findFirst(appletConfiguration, 4, function(node) {
			return node && typeof node.pageStack !== "undefined" && typeof node.footer !== "undefined"
		})

		if (!categoriesStrip || !appItem) {
			return false
		}

		// Collapse & hide the outer strip.
		categoriesStrip.visible = false
		categoriesStrip.enabled = false
		categoriesStrip.width = 0

		// Hide any vertical separator next to it.
		var sep = _findFirst(appletConfiguration, 2, function(node) {
			var isSep = ("" + node).indexOf("Separator") !== -1
			if (!isSep || !node.anchors) {
				return false
			}
			// Typically the vertical separator has top/left/bottom anchors and no right anchor.
			return node.anchors.top && node.anchors.bottom && node.anchors.left && !node.anchors.right
		})
		if (sep) {
			sep.visible = false
			if (typeof sep.width !== "undefined") {
				sep.width = 0
			}
		}

		// Re-anchor the app container to the left edge so it uses full width.
		if (appItem.anchors) {
			appItem.anchors.left = appletConfiguration.left
			appItem.anchors.leftMargin = 0
		}

		return true
	}

	function _hideHostApplyButtonOnce() {
		// Plasma's AppletConfiguration.qml defines an Apply button in the footer.
		// It is often redundant for our settings shell; hide it to avoid a
		// permanently-disabled control in the UI.
		function isClassName(item, className) {
			var itemClassName = ("" + item).split("_", 1)[0]
			return itemClassName === className
		}
		function getAncestor(item, className) {
			var curItem = item
			while (curItem && curItem.parent) {
				curItem = curItem.parent
				if (isClassName(curItem, className)) {
					return curItem
				}
			}
			return null
		}

		if (typeof root === "undefined" || !root) {
			return false
		}
		var appletConfiguration = isClassName(root, "AppletConfiguration") ? root : getAncestor(root, "AppletConfiguration")
		if (!appletConfiguration) {
			return false
		}

		var applyButton = _findFirst(appletConfiguration, 6, function(node) {
			if (!node) {
				return false
			}
			// Match by icon name; text is translated.
			try {
				return node.icon && node.icon.name === "dialog-ok-apply"
			} catch (e) {
				return false
			}
		})

		if (!applyButton) {
			return false
		}

		applyButton.visible = false
		applyButton.enabled = false
		// Try to also remove any remaining layout allocation.
		if (typeof applyButton.implicitWidth !== "undefined") {
			applyButton.implicitWidth = 0
		}
		if (typeof applyButton.width !== "undefined") {
			applyButton.width = 0
		}
		if (typeof applyButton.Layout !== "undefined") {
			applyButton.Layout.preferredWidth = 0
			applyButton.Layout.maximumWidth = 0
		}
		return true
	}

	RowLayout {
		anchors.fill: parent
		spacing: Kirigami.Units.largeSpacing

		QQC2.Frame {
			Layout.fillHeight: true
			Layout.preferredWidth: Kirigami.Units.gridUnit * 12
			Layout.minimumWidth: Kirigami.Units.gridUnit * 10

			ColumnLayout {
				anchors.fill: parent
				spacing: Kirigami.Units.smallSpacing

				QQC2.TextField {
					id: searchField
					Layout.fillWidth: true
					placeholderText: i18n("Search...")
					text: page.filterText
					onTextChanged: page.filterText = text
					selectByMouse: true
					// QQC2 TextField doesn't reliably expose a clear button across all
					// Plasma/Qt6 style versions; avoid using non-portable properties.
				}


				// Keep the navigation list fixed; only the right pane should scroll.
				ListView {
					id: sectionList
					Layout.fillWidth: true
					Layout.fillHeight: true
					clip: true
					interactive: false
					boundsBehavior: Flickable.StopAtBounds
					model: page.filteredSections
					currentIndex: {
						for (var i = 0; i < page.filteredSections.length; i++) {
							if (page.filteredSections[i].key === page.currentSectionKey) {
								return i
							}
						}
						return -1
					}
					delegate: QQC2.ItemDelegate {
						width: ListView.view.width
						text: modelData.name
						icon.name: modelData.icon
						highlighted: modelData.key === page.currentSectionKey
						onClicked: page.currentSectionKey = modelData.key
					}
				}
			}
		}

		ColumnLayout {
			Layout.fillWidth: true
			Layout.fillHeight: true
			spacing: Kirigami.Units.smallSpacing

			Kirigami.Heading {
				Layout.fillWidth: true
				level: 2
				text: {
					var s = page._sectionByKey(page.currentSectionKey)
					return s ? s.name : ""
				}
			}

			QQC2.Frame {
				Layout.fillWidth: true
				Layout.fillHeight: true

				Loader {
					id: sectionLoader
					anchors.fill: parent
					active: !!page.currentSectionKey
					source: {
						var s = page._sectionByKey(page.currentSectionKey)
						return s ? s.source : ""
					}
					onLoaded: {
						// Ensure the loaded page fills our content pane.
						if (item && item.anchors) {
							item.anchors.fill = sectionLoader
						}
						if (item && typeof item.Layout !== "undefined") {
							item.Layout.fillWidth = true
							item.Layout.fillHeight = true
						}
					}
				}
			}
		}
	}
}
