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
    return '<iframe src="http://192.168.59.103:32768/countly" frameborder="0"></iframe>'
  }
}
