import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.draganddrop as DragAndDrop
import org.kde.kquickcontrolsaddons as KQuickControlsAddons
import "Utils.js" as Utils


AppToolButton {
	id: itemDelegate
	preventStealing: true

	KQuickControlsAddons.Clipboard {
		id: clipboard
	}

	width: ListView.view.width
	implicitHeight: row.implicitHeight

	property var parentModel: typeof modelList !== "undefined" && modelList[index] ? modelList[index].parentModel : undefined
	property string modelDescription: model.name == model.description ? '' : model.description // Ignore the Comment if it's the same as the Name.
	property string description: model.url ? modelDescription : '' // 
	property bool isDesktopFile: !!(model.url && endsWith(model.url, '.desktop'))
	property bool showItemUrl: listView.showItemUrl && (!isDesktopFile || listView.showDesktopFileUrl)
	property string secondRowText: showItemUrl && model.url ? model.url : modelDescription
	property bool secondRowVisible: secondRowText
	property string launcherUrl: model.favoriteId || model.url
	property string iconName: model.iconName || ''
	property alias iconSource: itemIcon.source
	property int iconSize: model.largeIcon ? listView.iconSize * 2 : listView.iconSize

	// Tooltip: show full result text (name + description) when hovered
	property string fullResultTooltip: (model && model.name ? model.name : '') + ((model && model.description) ? ('\n' + model.description) : '')
	readonly property string tooltipMainText: (model && model.name) ? ('' + model.name) : ''
	readonly property string tooltipSubText: (model && model.description && model.description !== model.name) ? ('' + model.description) : ''

	// Plasma tooltip follows cursor without stealing hover (avoids flashing).
	PlasmaCore.ToolTipArea {
		anchors.fill: parent
		active: itemDelegate.containsMouse && (tooltipMainText.length > 0 || tooltipSubText.length > 0)
		mainText: tooltipMainText
		subText: tooltipSubText
	}

	function endsWith(s, substr) {
		return s.indexOf(substr) == s.length - substr.length
	}

	// We need to look at the js list since ListModel doesn't support item's with non primitive propeties (like an Image).
	property bool modelListPopulated: !!listView.model.list && listView.model.list.length - 1 >= index

	// Drag (based on kicker)
	// https://github.com/KDE/plasma-desktop/blob/4aad3fdf16bc5fd25035d3d59bb6968e06f86ec6/applets/kicker/package/contents/ui/ItemListDelegate.qml#L96
	// https://github.com/KDE/plasma-desktop/blob/master/applets/kicker/plugin/draghelper.cpp
	property int pressX: -1
	property int pressY: -1
	property bool dragEnabled: launcherUrl
	function initDrag(mouse) {
		pressX = mouse.x
		pressY = mouse.y
	}
	function shouldStartDrag(mouse) {
		return dragEnabled
			&& pressX != -1 // Drag initialized?
			&& dragHelper.isDrag(pressX, pressY, mouse.x, mouse.y) // Mouse moved far enough?
	}
	function startDrag() {
		// Note that we fallback from url to favoriteId for "Most Used" apps.
		
		var dragIcon = iconSource
		dragHelper.startDrag(widget, model.url || model.favoriteId, dragIcon, "favoriteId", model.favoriteId)

		resetDragState()
	}
	function resetDragState() {
		pressX = -1
		pressY = -1
	}
	onPressed: function(mouse) {
		//("click menu ", model.iconName)
		if (mouse.buttons & Qt.LeftButton) {
			initDrag(mouse)
		} else if (mouse.buttons & Qt.RightButton) {
			mouse.accepted = true
			resetDragState()
			if (typeof logger !== "undefined" && logger) {
				logger.debug('MenuListItem.openContextMenu (pressed)', 'index', index, 'name', model && model.name)
			}
			var targetModel = contextMenuModel()
			// Avoid probing action lists on unsafe models (some runner models can hard-crash plasmashell).
			if (modelSupportsActionLists(targetModel) && targetModel && typeof targetModel.hasActionList === "function") {
				var hasActions = false
				try { hasActions = targetModel.hasActionList(index) } catch (e) { hasActions = false; console.warn('MenuListItem.hasActionList exception', e) }
			}
			contextMenu.open(mouse.x, mouse.y)
		}
	}
	onContainsMouseChanged: function(containsMouse) {
		if (!containsMouse) {
			resetDragState()
		}
	}
	onPositionChanged: function(mouse) {
		if (shouldStartDrag(mouse)) {
			startDrag()
		}
	}

	RowLayout { // ItemListDelegate
		id: row
		anchors.left: parent.left
		anchors.leftMargin: Kirigami.Units.smallSpacing
		anchors.right: parent.right
		anchors.rightMargin: Kirigami.Units.smallSpacing

		Item {
			Layout.fillHeight: true
			implicitHeight: itemIcon.implicitHeight
			implicitWidth: itemIcon.implicitWidth

			Kirigami.Icon {
				id: itemIcon
				anchors.centerIn: parent
				implicitHeight: itemDelegate.iconSize
				implicitWidth: implicitHeight

				animated: true
				source: itemDelegate.iconName || itemDelegate.iconInstance
			}
		}

		ColumnLayout {
			Layout.fillWidth: true
			Layout.alignment: Qt.AlignVCenter
			spacing: 0

			RowLayout {
				Layout.fillWidth: true

				PlasmaComponents3.Label {
					id: itemLabel
					text: model.name
					maximumLineCount: 1
					height: implicitHeight
				}

				PlasmaComponents3.Label {
					Layout.fillWidth: true
					text: !itemDelegate.secondRowVisible ? itemDelegate.description : ''
					color: config.menuItemTextColor2
					maximumLineCount: 1
					elide: Text.ElideRight
					height: implicitHeight // ElideRight causes some top padding for some reason
				}
			}

			PlasmaComponents3.Label {
				visible: itemDelegate.secondRowVisible
				Layout.fillWidth: true
				text: itemDelegate.secondRowText
				color: config.menuItemTextColor2
				maximumLineCount: 1
				elide: Text.ElideMiddle
				height: implicitHeight
			}
		}

	}

	acceptedButtons: Qt.LeftButton | Qt.RightButton

	onClicked: function(mouse) {
		mouse.accepted = true
		resetDragState()
		if (typeof logger !== "undefined" && logger) {
			logger.debug('MenuListItem.onClicked', 'button', mouse.button, 'index', index, 'name', model && model.name)
		}
		if (mouse.button == Qt.LeftButton) {
			trigger()
		}
	}

	function findAllAppsIndexForLauncher(launcherUrl) {
		if (!launcherUrl || !appsModel || !appsModel.allAppsModel || !appsModel.allAppsModel.list) {
			return -1
		}
		var parsed = Utils.parseDropUrl('' + launcherUrl)
		var raw = '' + launcherUrl
		var list = appsModel.allAppsModel.list
		for (var i = 0; i < list.length; i++) {
			var item = list[i]
			if (!item) {
				continue
			}
			// Compare against both favoriteId and url; try both raw and parsed forms.
			if (item.favoriteId === parsed || item.url === parsed || item.favoriteId === raw || item.url === raw) {
				return i
			}
		}
		return -1
	}

	function contextMenuModel() {
		return listView && listView.model ? listView.model : null
	}

	function modelSupportsTrigger(model) {
		return model && typeof model.triggerIndex === "function"
	}

	function modelSupportsActionLists(model) {
		if (typeof search !== "undefined" && model === search.results) {
			// Allowlist runners incrementally to avoid crashes.
			// Prefer stable IDs / URL patterns since runnerName can be localized.
			var item = null
			try { item = model.get(index) } catch (e) { item = null }
			var runnerId = item ? (item.runnerId || '') : ''
			var runnerName = item ? (item.runnerName || '') : ''
			var url = item ? (item.url || '') : ''

			var allowByRunnerId = runnerId === 'krunner_services'
			var allowByUrl = (typeof url === 'string') && (
				url.indexOf('applications://') === 0
				|| url.indexOf('applications:') === 0
				|| url.indexOf('systemsettings://') === 0
				|| url.indexOf('systemsettings:') === 0
				|| url.indexOf('settings://') === 0
				|| url.indexOf('kcm:') === 0
				|| url.indexOf('//kcm_') === 0
				|| endsWith(url, '.desktop')
			)
			var allowByRunnerName = runnerName === 'Applications' || runnerName === 'System Settings'

			if (!(allowByRunnerId || allowByUrl || allowByRunnerName)) {
				if (typeof logger !== "undefined" && logger) {
					logger.warn('MenuListItem: skipping action lists for search runner (not allowlisted)', index, runnerId || runnerName || 'no-item')
				}
				console.warn('MenuListItem: skipping action lists for search runner (not allowlisted)', index, runnerId || runnerName || 'no-item')
				return false
			}
		}
		return model
			&& typeof model.hasActionList === "function"
			&& typeof model.getActionList === "function"
			&& typeof model.triggerIndexAction === "function"
	}

	function trigger() {
		var targetModel = contextMenuModel()
		if (modelSupportsTrigger(targetModel)) {
			targetModel.triggerIndex(index)
		} else if (typeof logger !== "undefined" && logger) {
			logger.warn('MenuListItem.trigger: model missing triggerIndex()', targetModel)
		}
	}

	AppContextMenu {
		id: contextMenu
		onPopulateMenu: function(menu) {
			var targetModel = contextMenuModel()
			var isSearchResultsModel = (typeof search !== "undefined" && targetModel === search.results)
			var copyableValueRunnerIds = [
				'calculator',
				'unitconverter',
				'Dictionary',
				'org.kde.datetime',
			]
			var runnerId = (model && typeof model.runnerId !== 'undefined') ? ('' + model.runnerId) : ''
			function _normalizeCopyText(s) {
				if (typeof s === 'undefined' || s === null) {
					return ''
				}
				var t = ('' + s).trim()
				if (!t) {
					return ''
				}
				// Prefer a single line.
				var nl = t.indexOf('\n')
				if (nl >= 0) {
					t = t.substring(0, nl).trim()
				}
				// Collapse whitespace.
				t = t.replace(/\s+/g, ' ').trim()
				return t
			}
			function _extractValuePart(s) {
				var t = _normalizeCopyText(s)
				if (!t) {
					return ''
				}
				// Common patterns for value-like results.
				var splitters = ['=', '→', '=>', '->', ':']
				for (var si = 0; si < splitters.length; si++) {
					var sep = splitters[si]
					var p = t.lastIndexOf(sep)
					if (p >= 0 && p + sep.length < t.length) {
						var rhs = t.substring(p + sep.length).trim()
						if (rhs) {
							return rhs
						}
					}
				}
				return t
			}
			function _hasDigit(s) {
				return /\d/.test(s)
			}
			function _preferValueLike(a, b) {
				var aa = _extractValuePart(a)
				var bb = _extractValuePart(b)
				if (!aa) {
					return bb
				}
				if (!bb) {
					return aa
				}
				// Prefer digit-containing strings when possible.
				var aHas = _hasDigit(aa)
				var bHas = _hasDigit(bb)
				if (aHas && !bHas) {
					return aa
				}
				if (bHas && !aHas) {
					return bb
				}
				// Prefer the shorter one if both look similar.
				if (aa.length !== bb.length) {
					return aa.length < bb.length ? aa : bb
				}
				return aa
			}
			var copyText = ''
			if (model) {
				copyText = _preferValueLike(model.name, model.description)
			}
			var shouldShowCopy = isSearchResultsModel
				&& !!copyText
				&& (copyableValueRunnerIds.indexOf(runnerId) !== -1 || !launcherUrl)
			if (shouldShowCopy) {
				var copyMenuItem = menu.newMenuItem()
				copyMenuItem.text = i18n("Copy")
				copyMenuItem.icon = "edit-copy"
				copyMenuItem.enabled = copyText.length > 0
				copyMenuItem.clicked.connect(function() {
					clipboard.content = copyText
				})
				menu.addMenuItem(copyMenuItem)
			}
			if (launcherUrl && !plasmoid.configuration.tilesLocked) {
				menu.addPinToMenuAction(launcherUrl, {
					label: model.name,
					icon: itemIcon ? itemIcon.source : (model.iconName || model.icon || ""),
					url: model.url || "",
				})
			}

			var isMergedSearch = isSearchResultsModel && search && search.runnerModel && !!search.runnerModel.mergeResults
			var shouldAttemptActions = modelSupportsActionLists(targetModel)
			var actionList = []
			if (isMergedSearch) {
				// When RunnerModel.mergeResults is enabled, the merged runner model can hard-crash plasmashell
				// if we query ActionListRole. For app-like results, resolve actions from the All Apps model instead.
				var appIndex = findAllAppsIndexForLauncher(launcherUrl)
				if (appIndex >= 0 && appsModel.allAppsModel && typeof appsModel.allAppsModel.getActionList === "function") {
					try { actionList = appsModel.allAppsModel.getActionList(appIndex) } catch (e) { actionList = [] }
					if (actionList && typeof actionList.length === "number" && actionList.length > 0) {
						menu.addActionList(actionList, appsModel.allAppsModel, appIndex)
					}
				}
			} else if (shouldAttemptActions) {
				try {
					actionList = targetModel.getActionList(index)
				} catch (e) {
					actionList = []
					if (typeof logger !== "undefined" && logger) {
						logger.warn('MenuListItem: getActionList exception', index, e)
					}
				}
			} else if (targetModel && !isSearchResultsModel && typeof targetModel.getActionList === "function") {
				// Some models may not advertise hasActionList but still return actions; try them defensively (not for search to avoid runner crashes).
				try {
					actionList = targetModel.getActionList(index)
				} catch (e) {
					actionList = []
					if (typeof logger !== "undefined" && logger) {
						logger.warn('MenuListItem: fallback getActionList exception', index, e)
					}
				}
			}
			if (!isMergedSearch && actionList && typeof actionList.length === "number" && actionList.length > 0 && targetModel && typeof targetModel.triggerIndexAction === "function") {
				menu.addActionList(actionList, targetModel, index)
			} else if (typeof logger !== "undefined" && logger && targetModel && shouldAttemptActions) {
				logger.warn('MenuListItem: context menu skipped action list; model missing action helpers or empty actions', targetModel)
			}
		}
	}

} // delegate: AppToolButton
