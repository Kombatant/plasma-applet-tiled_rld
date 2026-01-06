import QtQuick

KickerListView { // RunnerResultsList
	id: searchResultsList

	model: search.results
	delegate: MenuListItem {
		property var runner: search.runnerModel.modelForRow(model.runnerIndex)
		readonly property bool hasRunnerRow: runner && typeof runner.count === 'number'
			&& model.runnerItemIndex >= 0 && model.runnerItemIndex < runner.count
		iconSource: hasRunnerRow ? runner.data(runner.index(model.runnerItemIndex, 0), Qt.DecorationRole) : ""
		Component.onCompleted: {
			if (!hasRunnerRow && typeof logger !== "undefined" && logger) {
				logger.warn('SearchResultsList.delegate: missing runner row', model.runnerIndex, model.runnerItemIndex, runner ? runner.count : 'no-runner')
			}
		}
		iconSize: config.appListIconSize
	}
	
	section.property: plasmoid.configuration.searchResultsGrouped ? 'sectionName' : ''
	section.criteria: ViewSection.FullString

	Connections {
		target: search.results
		function onRefreshing() {
			searchResultsList.currentIndex = 0
		}
		function onRefreshed() {
			searchResultsList.currentIndex = 0
		}
	}

}
