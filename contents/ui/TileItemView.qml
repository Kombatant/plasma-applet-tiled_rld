import QtQuick
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import Qt5Compat.GraphicalEffects as QtGraphicalEffects

Rectangle {
	id: tileItemView
	color: appObj.backgroundColor
	radius: cornerRadius
	readonly property real cornerRadius: (config && config.tileCornerRadius ? config.tileCornerRadius : 0)
	property color gradientBottomColor: Qt.darker(appObj.backgroundColor, 2.0)

	function _fileExtFromUrl(url) {
		if (!url) {
			return ""
		}
		var s = ("" + url).toLowerCase()
		// Strip query/fragment to make extension detection more reliable.
		var q = s.indexOf("?")
		if (q >= 0) {
			s = s.substring(0, q)
		}
		var h = s.indexOf("#")
		if (h >= 0) {
			s = s.substring(0, h)
		}
		// For file URLs, keep the path portion; extension logic works either way.
		var dot = s.lastIndexOf(".")
		if (dot < 0 || dot === s.length - 1) {
			return ""
		}
		return s.substring(dot + 1)
	}

	readonly property bool backgroundIsAnimated: {
		var ext = _fileExtFromUrl(appObj.backgroundImage)
		return ext === "gif" || ext === "apng" || ext === "webp"
	}
	readonly property bool backgroundAnimatedLoadFailed: backgroundIsAnimated && backgroundAnimatedImage.status === Image.Error
	readonly property bool backgroundUseAnimatedRenderer: backgroundIsAnimated && !backgroundAnimatedLoadFailed

	Component {
		id: tileGradient
		Gradient {
			GradientStop { position: 0.0; color: appObj.backgroundColor }
			GradientStop { position: 1.0; color: tileItemView.gradientBottomColor }
		}
	}
	gradient: appObj.backgroundGradient ? tileGradient.createObject(tileItemView) : null

	readonly property real tilePadding: 4 * Screen.devicePixelRatio
	readonly property real iconBaseSize: (plasmoid && plasmoid.configuration && plasmoid.configuration.tileIconSize ? plasmoid.configuration.tileIconSize : 72) * Screen.devicePixelRatio
	readonly property real smallIconSize: Math.max(16 * Screen.devicePixelRatio, Math.round(iconBaseSize * 0.45))
	readonly property real mediumIconSize: Math.max(16 * Screen.devicePixelRatio, Math.round(iconBaseSize))
	readonly property real largeIconSize: Math.max(16 * Screen.devicePixelRatio, Math.round(iconBaseSize * 1.33))

	readonly property int labelAlignment: appObj.isGroup ? config.groupLabelAlignment : config.tileLabelAlignment
	readonly property bool labelBelowIcon: !(modelData.w >= 2 && modelData.h == 1)

	property bool hovered: false

	states: [
		State {
			when: modelData.w == 1 && modelData.h >= 1
			PropertyChanges { target: icon; size: smallIconSize }
			PropertyChanges { target: label; visible: false }
		},
		State {
			when: modelData.w >= 2 && modelData.h == 1
			AnchorChanges { target: icon
				anchors.horizontalCenter: undefined
				anchors.left: tileItemView.left
			}
			PropertyChanges { target: icon; anchors.leftMargin: tilePadding }
			PropertyChanges { target: label
				verticalAlignment: Text.AlignVCenter
			}
			AnchorChanges { target: label
				anchors.left: icon.right
			}
		},
		State {
			when: (modelData.w >= 2 && modelData.h == 2) || (modelData.w == 2 && modelData.h >= 2)
			PropertyChanges { target: icon; size: mediumIconSize }
		},
		State {
			when: modelData.w >= 3 && modelData.h >= 3
			PropertyChanges { target: icon; size: largeIconSize }
		}
	]

	Item {
		id: contentLayer
		anchors.fill: parent

		AnimatedImage {
			id: backgroundAnimatedImage
			anchors.fill: parent
			visible: !!appObj.backgroundImage && tileItemView.backgroundUseAnimatedRenderer
			source: tileItemView.backgroundIsAnimated ? appObj.backgroundImage : ""
			fillMode: Image.PreserveAspectCrop
			asynchronous: true
			playing: visible
		}

		Image {
			id: backgroundImage
			anchors.fill: parent
			visible: !!appObj.backgroundImage && (!tileItemView.backgroundIsAnimated || tileItemView.backgroundAnimatedLoadFailed)
			source: appObj.backgroundImage
			fillMode: Image.PreserveAspectCrop
			asynchronous: true
		}

		Kirigami.Icon {
			id: icon
			visible: appObj.showIcon
			source: appObj.iconSource
			anchors.verticalCenter: parent.verticalCenter
			anchors.horizontalCenter: parent.horizontalCenter
			property int size: Math.min(parent.width, parent.height) / 2
			width: appObj.showIcon ? size : 0
			height: appObj.showIcon ? size : 0
			anchors.fill: appObj.iconFill ? parent : null
			smooth: appObj.iconFill
		}

		PlasmaComponents3.Label {
			id: label
			visible: false // Label is rendered outside the tile (below) in TileItem.qml
			text: appObj.labelText
			anchors.top: parent.top
			anchors.bottom: parent.bottom
			anchors.leftMargin: tilePadding
			anchors.rightMargin: tilePadding
			anchors.left: parent.left
			anchors.right: parent.right
			wrapMode: Text.Wrap
			horizontalAlignment: labelBelowIcon ? Text.AlignHCenter : labelAlignment
			verticalAlignment: Text.AlignBottom
			width: parent.width
			renderType: Text.QtRendering // Fix pixelation when scaling. Plasma.Label uses NativeRendering.
			style: Text.Outline
			styleColor: appObj.backgroundGradient ? tileItemView.gradientBottomColor : appObj.backgroundColor
		}
	}

	Rectangle {
		id: roundedMask
		anchors.fill: parent
		radius: tileItemView.cornerRadius
		visible: false
	}

	ShaderEffectSource {
		id: contentSource
		sourceItem: contentLayer
		recursive: true
		live: true
		hideSource: true
	}

	QtGraphicalEffects.OpacityMask {
		anchors.fill: parent
		source: contentSource
		maskSource: roundedMask
	}
}
