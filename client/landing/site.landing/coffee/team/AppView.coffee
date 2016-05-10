kd = require 'kd'


module.exports = class TeamView extends kd.View

  TABS =
    login           : require './tabs/teamlogintab'
    recover         : require './tabs/teamrecovertab'
    reset           : require './tabs/teamresettab'
    domain          : require './tabs/teamdomaintab'
    username        : require './tabs/teamusernametab'
    join            : require './tabs/teamjointab'
    banned          : require './tabs/teambannedtab'
    authenticate    : require './tabs/teamauthenticatetab'
    # welcome         : require './tabs/teamwelcometab'
    # 'email-domains' : require './tabs/teamalloweddomaintab'
    # invite          : require './tabs/teaminvitetab'
    # congrats        : require './tabs/teamcongratstab'
    # stacks          : require './tabs/teamstackstab'


  constructor: (options = {}, data) ->

    super options, data

    @addSubView @tabView = new kd.TabView
      tagName             : 'main'
      hideHandleContainer : yes

    # focus to the first element of the form if there is any form
    @tabView.on 'PaneDidShow', (pane) -> pane.form?.focusFirstElement()


  showTab: (step, query) ->

    return kd.singletons.router.handleRoute '/Teams'  unless TABS[step]

    if tab = @tabView.getPaneByName step
    then @tabView.showPane tab
    else @tabView.addPane tab = new TABS[step] { query, name : step }

    @tabView.getActivePane().show()  if step is 'domain'

    return tab
