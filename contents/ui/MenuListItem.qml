import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.draganddrop as DragAndDrop
import "Utils.js" as Utils


AppToolButton {
	id: itemDelegate

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

	function endsWith(s, substr) {
		return s.indexOf(substr) == s.length - substr.length
	}

	// We need to look at the js list since ListModel doesn't support item's with non primitive propeties (like an Image).
	property bool modelListPopulated: !!listView.model.list && listView.model.list.length - 1 >= index
	//property var iconInstance: modelListPopulated && listView.model.list[index] ? listView.model.list[index].icon : ""
//	property var iconInstance: {
//     if (modelListPopulated && listView.model.list[index]) {
//         var item = listView.model.list[index];
//         // Try to access the icon in different ways
//         if (item.icon !== undefined) {
//             return item.icon;
//         } else if (item.decoration !== undefined) {
//             return item.decoration;
//         } else if (item.iconName !== undefined) {
//             return Qt.icon.fromTheme(item.iconName);
//         } else {
//             console.log("Debug - available properties:", Object.keys(item));
//             return "";
//         }
//     } else {
//         return "";
//     }
// }
//      Kirigami.Icon {
// 		id: testname
//         source: iconName  // This uses the theme icon name directly
//     }
	// Connections {
	// 	target: listView.model
	// 	function onRefreshed() {
			
	// 		// We need to manually trigger an update when we update the model without replacing the list.
	// 		// Otherwise the icon won't be in sync.
	// 		itemDelegate.iconInstance = listView.model.list[index] ? listView.model.list[index].icon : ""
	// 	}
	// }

	// Drag (based on kicker)
	// https://github.com/KDE/plasma-desktop/blob/4aad3fdf16bc5fd25035d3d59bb6968e06f86ec6/applets/kicker/package/contents/ui/ItemListDelegate.qml#L96
	// https://github.com/KDE/plasma-desktop/blob/master/applets/kicker/plugin/draghelper.cpp
	property int pressX: -1
	property int pressY: -1
	property bool dragEnabled: launcherUrl
	function initDrag(mouse) {
		pressX = mouse.x
		//console.log("init drag")
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
		//console.log("start drag ", dragHelper.defaultIcon , dragIcon)
		//if (typeof dragIcon === "string") {
			//console.log("start drag ",dragHelper.defaultIcon)
			// startDrag must use QIcon. See Issue #75.
		  //   dragIcon = dragHelper.defaultIcon
			//dragIcon = null
		//}
		// console.log('startDrag', widget, model.url, "favoriteId", model.favoriteId)
		// console.log('    iconInstance', iconInstance)
		// console.log('    dragIcon', dragIcon)
		//if (dragIcon) {
			
			dragHelper.startDrag(widget, model.url || model.favoriteId, dragIcon, "favoriteId", model.favoriteId)
		//}

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

				// visible: iconsEnabled

				animated: true
				// usesPlasmaTheme: false
				source: itemDelegate.iconName || itemDelegate.iconInstance
			}
		}

		ColumnLayout {
			Layout.fillWidth: true
			// Layout.fillHeight: true
			Layout.alignment: Qt.AlignVCenter
			spacing: 0

			RowLayout {
				Layout.fillWidth: true
				// height: itemLabel.height

				PlasmaComponents3.Label {
					id: itemLabel
					text: model.name
					maximumLineCount: 1
					// elide: Text.ElideMiddle
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
				// Layout.fillHeight: true
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
		console.log('MenuListItem.onClicked', 'button', mouse.button, 'index', index, 'name', model && model.name)
		if (mouse.button == Qt.LeftButton) {
			trigger()
		} else if (mouse.button == Qt.RightButton) {
			if (typeof logger !== "undefined" && logger) {
				logger.debug('MenuListItem.openContextMenu', 'index', index, 'name', model && model.name)
			}
			console.log('MenuListItem.openContextMenu', 'index', index, 'name', model && model.name)
			var targetModel = contextMenuModel()
			// Avoid probing action lists on unsafe models (some runner models can hard-crash plasmashell).
			if (modelSupportsActionLists(targetModel) && targetModel && typeof targetModel.hasActionList === "function") {
				var hasActions = false
				try { hasActions = targetModel.hasActionList(index) } catch (e) { hasActions = false; console.warn('MenuListItem.hasActionList exception', e) }
				console.log('MenuListItem.hasActionList?', hasActions, 'runner', model && model.runnerName)
			}
			contextMenu.open(mouse.x, mouse.y)
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

			var allowByRunnerId = runnerId === 'services'
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

	// property bool hasActionList: listView.model.hasActionList(index)
	// property var actionList: hasActionList ? listView.model.getActionList(index) : []
	AppContextMenu {
		id: contextMenu
		onPopulateMenu: function(menu) {
			if (launcherUrl && !plasmoid.configuration.tilesLocked) {
				menu.addPinToMenuAction(launcherUrl, {
					label: model.name,
					icon: itemIcon ? itemIcon.source : (model.iconName || model.icon || ""),
					url: model.url || "",
				})
			}

			var targetModel = contextMenuModel()
			var isSearchResultsModel = (typeof search !== "undefined" && targetModel === search.results)
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
