import kd from 'kd'
import debug from 'debug'
import lazyrouter from 'app/lazyrouter'
import getCurrentGroup from 'app/util/getGroup'

const log = debug('analytics-view:router')

export default function() {
  lazyrouter.bind('analytics', (type, info, state, path, ctx) => {
    getCurrentGroup().fetchDataAt('countly.apiKey', (err, apiKey) => {
      if (!err) {
        log("couldn't fetch countly apikey")
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
