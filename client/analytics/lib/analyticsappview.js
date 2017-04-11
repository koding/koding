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
    
    // TODO: replace username with group.slug and replace apiKey with group's api key
    var username =  'admin'
    var apiKey = 'e6bfab40a224d55a2f5d40c83abc7ed4'
    var query = 'user=' + username + '&api_key=' + apiKey 
    
    return '<iframe src="/countly/sso/login?'+query+'" frameborder="0" width="100%" height="100%" border="0"></iframe>'
  }
}
