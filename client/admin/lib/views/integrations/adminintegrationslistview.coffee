kd                          = require 'kd'
KDView                      = kd.View
remote                      = require('app/remote').getInstance()
KDCustomHTMLView            = kd.CustomHTMLView
KDCustomScrollView          = kd.CustomScrollView
KDListViewController        = kd.ListViewController
AdminIntegrationItemView    = require './adminintegrationitemview'
AdminIntegrationSetupView   = require './adminintegrationsetupview'
AdminIntegrationDetailsView = require './adminintegrationdetailsview'

DUMMY_DATA   =
  list       : [
    { name   : 'Airbrake',        logo: 'https://koding-cdn.s3.amazonaws.com/temp-images/airbrake.png',       desc: 'Error monitoring and handling.'                       }
    { name   : 'Datadog',         logo: 'https://koding-cdn.s3.amazonaws.com/temp-images/datadog.png',        desc: 'SaaS app monitoring all in one place.'                }
    { name   : 'GitHub',          logo: 'https://koding-cdn.s3.amazonaws.com/temp-images/github.png',         desc: 'Source control and code management'                   }
    { name   : 'Pivotal Tracker', logo: 'https://koding-cdn.s3.amazonaws.com/temp-images/pivotaltracker.png', desc: 'Collaborative, lightweight agile project management.' }
    { name   : 'Travis CI',       logo: 'https://koding-cdn.s3.amazonaws.com/temp-images/travisci.png',       desc: 'Hosted software build services.'                      }
    { name   : 'Twitter',         logo: 'https://koding-cdn.s3.amazonaws.com/temp-images/twitter.png',        desc: 'Social networking and microblogging service.'         }
  ]


module.exports = class AdminIntegrationsListView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = 'all-integrations'

    super options, data

    @integrationType = @getOption 'integrationType'

    @createListController()
    @fetchIntegrations()

    @addSubView @subContentView = new KDCustomScrollView

  createListController: ->

    @listController       = new KDListViewController
      viewOptions         :
        wrapper           : yes
        itemClass         : AdminIntegrationItemView
      useCustomScrollView : yes
      noItemFoundWidget   : new KDCustomHTMLView
        cssClass          : 'hidden no-item-found'
        partial           : 'No integration available.'
      startWithLazyLoader : yes
      lazyLoaderOptions   :
        spinnerOptions    :
          size            : width: 28

    @addSubView @listController.getView()


  fetchIntegrations: ->

    # fake like we are fetching data from backend and make the flow async
    remote.api.JAccount.some {}, {}, (err, data) =>
      data = DUMMY_DATA.list

      if @integrationType is 'configured' # dummy code.
        data = data.first

      return @handleNoItem err  if err

      for item in data
        item.integrationType = @integrationType
        listItem = @listController.addItem item
        @registerListItem listItem

      @listController.lazyLoader.hide()


  registerListItem: (item) ->

    item.on 'IntegrationConfigureRequested', @bound 'showIntegrationDetails'

    item.on 'IntegrationGroupsFetched', (data) =>
      setupView = new AdminIntegrationSetupView {}, data
      setupView.once 'KDObjectWillBeDestroyed', @bound 'showList'
      setupView.once 'NewIntegrationAdded',     @bound 'showIntegrationDetails'

      @showView setupView


  showView: (view) ->

    @listController.getView().hide()
    @subContentView.wrapper.destroySubViews()
    @subContentView.wrapper.addSubView view


  showList: ->

    @subContentView.wrapper.destroySubViews()
    @listController.getView().show()


  showIntegrationDetails: (data) ->

    @showView new AdminIntegrationDetailsView {}, data


  handleNoItem: (err) ->

    kd.warn err
    @listController.lazyLoader.hide()
    @listController.noItemView.show()
