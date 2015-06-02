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
        { name: 'Airbrake',        logo: 'https://koding-cdn.s3.amazonaws.com/temp-images/airbrake.png',       desc: 'Error monitoring and handling.'                       }
        { name: 'Datadog',         logo: 'https://koding-cdn.s3.amazonaws.com/temp-images/datadog.png',        desc: 'SaaS app monitoring all in one place.'                }
        { name: 'GitHub',          logo: 'https://koding-cdn.s3.amazonaws.com/temp-images/github.png',         desc: 'Source control and code management'                   }
        { name: 'Pivotal Tracker', logo: 'https://koding-cdn.s3.amazonaws.com/temp-images/pivotaltracker.png', desc: 'Collaborative, lightweight agile project management.' }
        { name: 'Travis CI',       logo: 'https://koding-cdn.s3.amazonaws.com/temp-images/travisci.png',       desc: 'Hosted software build services.'                      }
        { name: 'Twitter',         logo: 'https://koding-cdn.s3.amazonaws.com/temp-images/twitter.png',        desc: 'Social networking and microblogging service.'         }
      ]

      return @handleNoItem err  if err

      @listController.addItem item  for item in data
      @listController.lazyLoader.hide()


  handleNoItem: (err) ->

    kd.warn err
    @listController.lazyLoader.hide()
    @listController.noItemView.show()
