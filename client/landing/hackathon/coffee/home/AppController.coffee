# SplashView = require './AppView'
HomeView   = require './AppViewFullResults'

module.exports = class HomeAppController extends KDViewController

  KD.registerAppClass this,
    name  : 'Home'
    route : '/Hackathon2014'


  constructor: (options = {}, data) ->

    options.view = new HomeView
      cssClass   : 'content-page results full'

    # dateString = KD.campaignStats?.campaign?.startDate or 'Mon Oct 27 2014 10:00:00 GMT-0700 (PDT)'
    # startDate  = new Date dateString

    # if Date.now() > startDate
    #   options.view = new HomeView
    #     cssClass   : 'content-page home full'
    # else
    #   options.view = new SplashView
    #     cssClass   : 'content-page home'


    super options, data
