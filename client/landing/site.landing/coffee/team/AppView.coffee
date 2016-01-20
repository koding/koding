module.exports = class TeamView extends KDView

  TABS =
    login           : require './tabs/teamlogintab'
    domain          : require './tabs/teamdomaintab'
    username        : require './tabs/teamusernametab'
    join            : require './tabs/teamjointab'
    welcome         : require './tabs/teamwelcometab'
    banned          : require './tabs/teambannedtab'
    authenticate    : require './tabs/teamauthenticatetab'
    # 'email-domains' : require './tabs/teamalloweddomaintab'
    # invite          : require './tabs/teaminvitetab'
    # congrats        : require './tabs/teamcongratstab'
    # stacks          : require './tabs/teamstackstab'

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
    else @tabView.addPane new TABS[step] { query, name : step }

    @tabView.getActivePane().show()  if step is 'domain'
