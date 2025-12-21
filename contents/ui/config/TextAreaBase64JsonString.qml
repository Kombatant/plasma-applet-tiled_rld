import QtQuick
import QtQuick.Layouts

import ".." as TiledMenu
import "../libconfig" as LibConfig

LibConfig.TextArea {
	id: textArea
	Layout.fillWidth: true
	font.family: "monospace"
	// JSON is structured; wrapping tends to make it harder to read.
	// Prefer preserving lines and letting the ScrollView provide horizontal scrolling.
	wrapMode: TextEdit.NoWrap

	property var base64JsonString: TiledMenu.Base64JsonString {
		id: base64JsonString
	}

	property alias jsonKey: base64JsonString.configKey
	property alias defaultValue: base64JsonString.defaultValue

	property alias enabled: textArea.enabled

	readonly property var configValue: configKey ? plasmoid.configuration[configKey] : ""
	onConfigValueChanged: deserialize()
	readonly property var value: base64JsonString.value

	property alias textArea: textArea
	property alias textAreaText: textArea.text

	property string indent: '  '

	function parseValue(value) {
		return JSON.stringify(value, null, indent)
	}
	function parseText(text) {
		return JSON.parse(text)
	}

	function setValue(val) {
		var newText = parseValue(val)
		if (textArea.text != newText) {
			textArea.text = newText
		}
	}

	function deserialize() {
		if (!textArea.focus) {
			setValue(value)
		}
	}
	function serialize() {
		var newValue = parseText(textArea.text)
		base64JsonString.set(newValue)
	}
}
