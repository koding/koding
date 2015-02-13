kd = require 'kd'
KDNotificationView = kd.NotificationView
isLoggedIn = require 'app/util/isLoggedIn'
lazyrouter = require 'app/lazyrouter'


handleSection = (callback) -> kd.singletons.mainController.ready ->

  if isLoggedIn()
    appManager = kd.singleton('appManager')
    if appManager.getFrontApp()?.getOption('name') is 'Account'
      callback appManager.getFrontApp()
    else appManager.open 'Account', callback
  else
    kd.singletons.router.handleRoute '/'

handle = ({params:{section}}) -> handleSection (app) -> app.openSection section

module.exports = -> lazyrouter.bind 'account', (type, info, state, path, ctx) ->

  switch type
    when 'profile'
      kd.singletons.router.handleRoute '/Account/Profile'
    when 'verified'
      new KDNotificationView title: "Thanks for verifying"
      ctx.clear()
    when 'verification-failed'
      new KDNotificationView title: "Verification failed!"
      ctx.clear()
    when 'referrer' then kd.singletons.router.handleRoute '/'
    when 'section' then handle info

