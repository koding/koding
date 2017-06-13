import kd from 'kd'
import getCurrentGroup from 'app/util/getGroup'

export default class AnalyticsAppView extends kd.View {
  constructor(options = {}, data) {
    options.testPath = 'analytics'
    if (!options.cssClass) {
      options.cssClass = kd.utils.curry('AnalyticsAppView', options.cssClass)
    }

    super(options, data)

    const team = getCurrentGroup()

    this.countlyUsername = team.slug
    this.countlyApiKey = ''
  }

  setApiKey(key) {
    return (this.countlyApiKey = key)
  }

  addCountlyFrame(key) {
    if (!key) {
      return null
    }
    this.setApiKey(key)
    let query = `user=${this.countlyUsername}&api_key=${this.countlyApiKey}`
    let app = new kd.View({
      tagName: 'iframe',
      attributes: {
        src: `/countly/sso/login?${query}`,
        frameborder: 0,
        border: 0,
        width: '100%',
        height: '100%',
      },
    })
    return this.addSubView(app)
  }
}
