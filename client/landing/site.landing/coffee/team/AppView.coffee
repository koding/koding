module.exports = class TeamView extends KDView

  TABS =
    login         : require './tabs/teamlogintab'
    domain        : require './tabs/teamdomaintab'
    alloweddomain : require './tabs/teamalloweddomaintab'
    invite        : require './tabs/teaminvitetab'
    username      : require './tabs/teamusernametab'
    welcome       : require './tabs/teamwelcometab'
    register      : require './tabs/teamregistertab'
    congratz      : require './tabs/teamcongratztab'
    authenticate  : require './tabs/teamauthenticatetab'

  constructor: (options = {}, data) ->

    super options, data

    @addSubView @tabView = new KDTabView
      tagName             : 'main'
      hideHandleContainer : yes

    # focus to the first element of the form if there is any form
    @tabView.on 'PaneDidShow', (pane) -> pane.form?.focusFirstElement()


  showTab: (step, query) ->

    return KD.singletons.router.handleRoute '/Teams'  unless TABS[step]

    if tab = @tabView.getPaneByName step
    then @tabView.showTab tab
    else @tabView.addPane new TABS[step] { query }