import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore

MouseArea {
	id: popup
	focus: true
	Keys.priority: Keys.BeforeItem
	Keys.onPressed: function(event) {
		// Preserve Esc behavior (handled by focused controls / default handlers).
		if (event.key === Qt.Key_Escape) {
			return
		}

		// Don't steal modifier shortcuts.
		if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)) {
			return
		}

		// Only for "typing" keys; ignore navigation keys, etc.
		if (!event.text || event.text.length === 0) {
			return
		}
		var code = event.text.charCodeAt(0)
		if (isNaN(code) || code < 0x20 || code === 0x7f) {
			return
		}

		// If the user is already typing into another input, don't override.
		var afi = Qt.application.activeFocusItem
		if (afi && typeof afi.insert === "function" && searchView.searchField && afi !== searchView.searchField.inputItem) {
			return
		}

		// Ensure the search UI is visible (covers TilesOnly mode).
		if (searchView && typeof searchView.showSearchView === "function") {
			searchView.showSearchView()
		}

		if (searchView && searchView.searchField && typeof searchView.searchField.focusAndInsert === "function") {
			event.accepted = true
			searchView.searchField.focusAndInsert(event.text)
		}
	}
	property alias searchView: searchView
	property alias appsView: searchView.appsView
	property alias tileEditorView: searchView.tileEditorView
	property alias tileEditorViewLoader: searchView.tileEditorViewLoader
	property alias tileGrid: tileGrid

	function normalizeGroupHeaderHeights() {
		var model = config && config.tileModel ? config.tileModel.value : null
		if (!model || !model.length) {
			return
		}

		var groups = []
		for (var i = 0; i < model.length; i++) {
			var t = model[i]
			if (t && t.tileType === "group") {
				groups.push(t)
			}
		}
		if (!groups.length) {
			return
		}

		groups.sort(function(a, b) {
			if (a.y === b.y) {
				return (a.x || 0) - (b.x || 0)
			}
			return (a.y || 0) - (b.y || 0)
		})

		var changed = false
		for (var gi = 0; gi < groups.length; gi++) {
			var groupTile = groups[gi]
			var oldH = (typeof groupTile.h !== "undefined" ? groupTile.h : 1)
			if (oldH === 1) {
				continue
			}

			// Compute area using the existing (old) group height.
			var area = tileGrid.getGroupAreaRect(groupTile)
			var deltaY = 1 - oldH
			groupTile.h = 1

			if (deltaY !== 0) {
				for (var ti = 0; ti < model.length; ti++) {
					var tile = model[ti]
					if (!tile || tile === groupTile) {
						continue
					}
					if (tileGrid.tileWithin(tile, area.x1, area.y1, area.x2, area.y2)) {
						tile.y += deltaY
					}
				}
			}

			changed = true
		}

		if (changed) {
			tileGrid.tileModelChanged()
		}
	}

	function resetViewsAfterTileModelReload() {
		// Importing settings can replace the tileModel JS array and invalidate any
		// references held by editor views. Ensure the editor is fully destroyed.
		if (tileEditorViewLoader && tileEditorViewLoader.active) {
			tileEditorViewLoader.active = false
		}
		// Return to the user's default view.
		if (searchView && typeof searchView.showDefaultView === "function") {
			searchView.showDefaultView()
		}
	}

	Connections {
		target: config && config.tileModel ? config.tileModel : null
		function onLoaded() {
			popup.normalizeGroupHeaderHeights()
			popup.resetViewsAfterTileModelReload()
		}
	}

	// Persist user resizing (Meta + Right Click drag) across plasmashell restarts.
	// Width is represented indirectly via favGridCols; height is stored in popupHeight.
	property bool _persistSizeEnabled: false
	Timer {
		id: enablePersistSize
		interval: 0
		repeat: false
		onTriggered: popup._persistSizeEnabled = true
	}
	Component.onCompleted: enablePersistSize.start()

	Timer {
		id: persistSizeDebounced
		interval: 400
		repeat: false
		onTriggered: {
			// Save height in logical pixels.
			var dpr = Screen.devicePixelRatio || 1
			var logicalHeight = Math.round(popup.height / dpr)
			if (logicalHeight > 0 && plasmoid.configuration.popupHeight !== logicalHeight) {
				plasmoid.configuration.popupHeight = logicalHeight
			}

			// Save width by converting the right-side tile area into a column count.
			var favWidth = Math.max(0, popup.width - config.leftSectionWidth)
			var box = config.cellBoxSize
			if (box > 0) {
				var cols = Math.floor(favWidth / box)
				cols = Math.max(1, cols)
				if (plasmoid.configuration.favGridCols !== cols) {
					plasmoid.configuration.favGridCols = cols
				}
			}
		}
	}

	onWidthChanged: {
		if (popup._persistSizeEnabled) {
			persistSizeDebounced.restart()
		}
	}
	onHeightChanged: {
		if (popup._persistSizeEnabled) {
			persistSizeDebounced.restart()
		}
	}

	RowLayout {
		anchors.fill: parent
		spacing: 0

		Item {
			id: sidebarPlaceholder
			implicitWidth: config.sidebarWidth + config.sidebarRightMargin
			Layout.fillHeight: true
		}

		SearchView {
			id: searchView
			Layout.fillHeight: true
		}

		TileGrid {
			id: tileGrid
			Layout.fillWidth: true
			Layout.fillHeight: true

			cellSize: config.cellSize
			cellMargin: config.cellMargin
			cellPushedMargin: config.cellPushedMargin

			tileModel: config.tileModel.value

			onEditTile: function(tile) { tileEditorViewLoader.open(tile) }

			onTileModelChanged: saveTileModel.restart()
			Timer {
				id: saveTileModel
				interval: 2000
				onTriggered: config.tileModel.save()
			}
		}
		
	}

	SidebarView {
		id: sidebarView
	}

	MouseArea {
		visible: !plasmoid.configuration.tilesLocked && !(plasmoid.location == PlasmaCore.Types.TopEdge || plasmoid.location == PlasmaCore.Types.RightEdge)
		anchors.top: parent.top
		anchors.right: parent.right
		width: Kirigami.Units.largeSpacing
		height: Kirigami.Units.largeSpacing
		cursorShape: Qt.WhatsThisCursor

		PlasmaCore.ToolTipArea {
			anchors.fill: parent
			icon: "help-hint"
			mainText: i18n("Resize?")
			subText: i18n("Meta + Right Click to resize the menu.")
		}
	}

	MouseArea {
		visible: !plasmoid.configuration.tilesLocked && !(plasmoid.location == PlasmaCore.Types.BottomEdge || plasmoid.location == PlasmaCore.Types.RightEdge)
		anchors.bottom: parent.bottom
		anchors.right: parent.right
		width: Kirigami.Units.largeSpacing
		height: Kirigami.Units.largeSpacing
		cursorShape: Qt.WhatsThisCursor

		PlasmaCore.ToolTipArea {
			anchors.fill: parent
			icon: "help-hint"
			mainText: i18n("Resize?")
			subText: i18n("Meta + Right Click to resize the menu.")
		}
	}

	onClicked: searchView.searchField.forceActiveFocus()
}
