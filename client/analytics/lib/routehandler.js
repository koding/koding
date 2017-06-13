import kd from 'kd'
import lazyrouter from 'app/lazyrouter'
import getCurrentGroup from 'app/util/getGroup'

const debug = require('debug')('analytics-view:router')

export default function() {
  lazyrouter.bind('analytics', (type, info, state, path, ctx) => {
    getCurrentGroup().fetchDataAt('countly.apiKey', (err, apiKey) => {
      if (err || !apiKey) {
        debug("couldn't fetch countly apikey")
        kd.singletons.notificationViewController.addNotification({
          type: 'warning',
          duration: 10000,
          content: 'Analytics is not available!',
        })
        return kd.singletons.router.handleRoute('/')
      } else {
        return kd.singletons.appManager.open('Analytics', app => {
          let view = app.getView()
          view.addCountlyFrame(apiKey)
        })
      }
    })
  })
}
