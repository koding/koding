TeamLoginTab         = require './teamlogintab'
TeamDomainTab        = require './teamdomaintab'
TeamAllowedDomainTab = require './teamalloweddomaintab'
TeamInviteTab        = require './teaminvitetab'
TeamUsernameTab      = require './teamusernametab'

module.exports = class TeamView extends KDView

  constructor:(options = {}, data)->

    super options, data

    @addSubView @tabView = new KDTabView
      tagName             : 'main'
      hideHandleContainer : yes


  createLoginTab: -> @tabView.addPane new TeamLoginTab

  createDomainTab: -> @tabView.addPane new TeamDomainTab

  createAllowedDomainTab: -> @tabView.addPane new TeamAllowedDomainTab

  createInviteTab: -> @tabView.addPane new TeamInviteTab

  createUsernameTab: -> @tabView.addPane new TeamUsernameTab
