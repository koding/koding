kd                       = require 'kd'
KDView                   = kd.View
remote                   = require('app/remote').getInstance()
KDCustomHTMLView         = kd.CustomHTMLView
KDListViewController     = kd.ListViewController
AdminIntegrationItemView = require './adminintegrationitemview'


module.exports = class AdminIntegrationsListView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = 'all-integrations'

    super options, data

    @createListController()
    @fetchIntegrations()


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
      data = [
        { name: 'Airbrake',        logo: 'https://slack.global.ssl.fastly.net/9f42/plugins/airbrake/assets/service_128.png', desc: 'Error monitoring and handling.'                       }
        { name: 'Datadog',         logo: 'https://slack.global.ssl.fastly.net/7bf4/img/services/datadog_128.png',            desc: 'SaaS app monitoring all in one place.'                }
        { name: 'GitHub',          logo: 'https://slack.global.ssl.fastly.net/5721/plugins/github/assets/service_128.png',   desc: 'Source control and code management'                   }
        { name: 'Pivotal Tracker', logo: 'https://slack.global.ssl.fastly.net/7bf4/img/services/pivotaltracker_128.png',     desc: 'Collaborative, lightweight agile project management.' }
        { name: 'Travis CI',       logo: 'https://slack.global.ssl.fastly.net/7bf4/img/services/travis_128.png',             desc: 'Hosted software build services.'                      }
        { name: 'Twitter',         logo: 'https://slack.global.ssl.fastly.net/7bf4/img/services/twitter_128.png',            desc: 'Social networking and microblogging service.'         }
      ]

      return @handleNoItem err  if err

      @listController.addItem item  for item in data
      @listController.lazyLoader.hide()


  handleNoItem: (err) ->

    kd.warn err
    @listController.lazyLoader.hide()
    @listController.noItemView.show()
