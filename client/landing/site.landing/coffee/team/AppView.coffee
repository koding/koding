module.exports = class TeamView extends KDView

  TABS =
    login         : require './teamlogintab'
    domain        : require './teamdomaintab'
    alloweddomain : require './teamalloweddomaintab'
    invite        : require './teaminvitetab'
    username      : require './teamusernametab'

  constructor:(options = {}, data)->

    super options, data

    @addSubView @tabView = new KDTabView
      tagName             : 'main'
      hideHandleContainer : yes



  showTab: (step, query) ->


    if tab = @tabView.getPaneByName step
    then @tabView.showTab tab
    else @tabView.addPane new TABS[step] { query }