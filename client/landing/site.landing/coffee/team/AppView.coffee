module.exports = class TeamView extends KDView

  TABS =
    login           : require './tabs/teamlogintab'
    domain          : require './tabs/teamdomaintab'
    'email-domains' : require './tabs/teamalloweddomaintab'
    invite          : require './tabs/teaminvitetab'
    username        : require './tabs/teamusernametab'
    welcome         : require './tabs/teamwelcometab'
    join            : require './tabs/teamusernametab'
    congrats        : require './tabs/teamcongratstab'
    stacks          : require './tabs/teamstackstab'
    banned          : require './tabs/teambannedtab'
    authenticate    : require './tabs/teamauthenticatetab'

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
    then @tabView.showPane tab
    else @tabView.addPane new TABS[step] { query }