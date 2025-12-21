import QtQuick
// import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

// import QtQuick.Controls.Styles.Plasma 2.0 as PlasmaStyles

Item {
	id: searchField

	signal escapeClearsSearchRequested()

	property int topMargin: 0
	property int bottomMargin: 0
	property real defaultFontSize: 16 * Screen.devicePixelRatio // Not the same as pointSize=16
	property real fontScale: 0.35
	readonly property real styleMaxFontSize: Math.max(0, height - topMargin - bottomMargin)
	readonly property real computedFontSize: Math.max(
		10 * Screen.devicePixelRatio,
		Math.min(styleMaxFontSize * fontScale, defaultFontSize)
	)

	property var listView: searchResultsView.listView
	property string text: search.query
	readonly property bool followsTheme: !!plasmoid.configuration.searchFieldFollowsTheme

	function onTextChangedInternal(newText) {
		if (text !== newText) {
			text = newText
		}
		if (search.query !== newText) {
			search.query = newText
		}
	}

	Connections {
		target: search
		function onQueryChanged() {
			if (searchField.text !== search.query) {
				searchField.text = search.query
			}
			if (fieldLoader.item && fieldLoader.item.text !== search.query) {
				fieldLoader.item.text = search.query
			}
		}
	}

	readonly property var inputItem: fieldLoader.item

	function focusAndInsert(insertText) {
		if (!searchField.inputItem) {
			return
		}
		searchField.inputItem.forceActiveFocus()
		if (typeof insertText !== "string" || insertText.length === 0) {
			return
		}
		if (typeof searchField.inputItem.insert === "function") {
			var pos = 0
			if (typeof searchField.inputItem.cursorPosition === "number") {
				pos = searchField.inputItem.cursorPosition
			} else if (typeof searchField.inputItem.length === "number") {
				pos = searchField.inputItem.length
			} else if (typeof searchField.inputItem.text === "string") {
				pos = searchField.inputItem.text.length
			}
			searchField.inputItem.insert(pos, insertText)
		} else {
			var base = (typeof searchField.inputItem.text === "string") ? searchField.inputItem.text : ""
			searchField.inputItem.text = base + insertText
		}
	}

	Loader {
		id: fieldLoader
		anchors.fill: parent
		sourceComponent: searchField.followsTheme ? themedField : windowsField
		onLoaded: {
			item.text = searchField.text
			item.forceActiveFocus()
		}
	}

	Component {
		id: themedField
		PlasmaComponents3.TextField {
			placeholderText: i18n("Search...")
			font.pixelSize: searchField.computedFontSize
			onTextChanged: searchField.onTextChangedInternal(text)
			Keys.onPressed: function(event) {
				if (event.key == Qt.Key_Up) {
					event.accepted = true; searchField.listView.goUp()
				} else if (event.key == Qt.Key_Down) {
					event.accepted = true; searchField.listView.goDown()
				} else if (event.key == Qt.Key_PageUp) {
					event.accepted = true; searchField.listView.pageUp()
				} else if (event.key == Qt.Key_PageDown) {
					event.accepted = true; searchField.listView.pageDown()
				} else if (event.key == Qt.Key_Return || event.key == Qt.Key_Enter) {
					event.accepted = true; searchField.listView.currentItem.trigger()
				} else if (event.modifiers & Qt.MetaModifier && event.key == Qt.Key_R) {
					event.accepted = true; search.filters = ['shell']
				} else if (event.key == Qt.Key_Escape) {
					if (searchField.text && searchField.text.length > 0) {
						event.accepted = true
						searchField.escapeClearsSearchRequested()
					} else {
						plasmoid.expanded = false
					}
				}
			}
		}
	}

	Component {
		id: windowsField
		PlasmaComponents3.TextField {
			placeholderText: i18n("Search...")
			font.pixelSize: searchField.computedFontSize
			background: Rectangle {
				color: "#eee"
			}
			color: "#111"
			placeholderTextColor: "#777"
			onTextChanged: searchField.onTextChangedInternal(text)
			Keys.onPressed: function(event) {
				if (event.key == Qt.Key_Up) {
					event.accepted = true; searchField.listView.goUp()
				} else if (event.key == Qt.Key_Down) {
					event.accepted = true; searchField.listView.goDown()
				} else if (event.key == Qt.Key_PageUp) {
					event.accepted = true; searchField.listView.pageUp()
				} else if (event.key == Qt.Key_PageDown) {
					event.accepted = true; searchField.listView.pageDown()
				} else if (event.key == Qt.Key_Return || event.key == Qt.Key_Enter) {
					event.accepted = true; searchField.listView.currentItem.trigger()
				} else if (event.modifiers & Qt.MetaModifier && event.key == Qt.Key_R) {
					event.accepted = true; search.filters = ['shell']
				} else if (event.key == Qt.Key_Escape) {
					if (searchField.text && searchField.text.length > 0) {
						event.accepted = true
						searchField.escapeClearsSearchRequested()
					} else {
						plasmoid.expanded = false
					}
				}
			}
		}
	}
}