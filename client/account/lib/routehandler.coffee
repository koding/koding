kd = require 'kd'
KDNotificationView = kd.NotificationView
lazyrouter = require 'app/lazyrouter'


handleSection = (path, callback) ->

  { appManager, router } = kd.singletons
  unless appManager.getFrontApp()
    appManager.once 'AppIsBeingShown', -> router.handleRoute path
    router.handleRoute '/IDE'
  else appManager.open 'Account', callback

handle = ({params:{section}}, path) ->
  handleSection path, (app) -> app.openSection section

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
    when 'section' then handle info, path

