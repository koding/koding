import kd from 'kd'
import AppController from 'app/appcontroller'
import AnalyticsAppView from './analyticsappview'

require('./routehandler')()
import 'analytics/styl'

export default class AnalyticsAppController extends AppController {
  constructor(options = {}, data) {
    if (data == null) {
      data = kd.singletons.groupsController.getCurrentGroup()
    }
    if (options.view == null) {
      options.view = new AnalyticsAppView({}, data)
    }
    super(options, data)
  }
  checkRoute(route) {
    return /^\/(?:Analytics).*/.test(route)
  }
}

AnalyticsAppController.options = {
  name: 'Analytics',
  behavior: 'application',
}
