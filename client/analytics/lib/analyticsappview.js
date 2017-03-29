import kd from 'kd'
import JView from 'app/jview'

export default class AnalyticsAppView extends JView {
  constructor (options = {}, data) {
    options.testPath = 'analytics'
    if (!options.cssClass) {
      options.cssClass = kd.utils.curry('AnalyticsAppView', options.cssClass)
    }

    super(options, data)
  }

  pistachio () {
    // return 'sinan\'s analytics'
    return '<iframe src="http://dev.koding.com:8090/countly" frameborder="0" width="100%" height="100%" border="0"></iframe>'
  }
}
