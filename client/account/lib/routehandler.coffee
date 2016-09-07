kd                 = require 'kd'
lazyrouter         = require 'app/lazyrouter'
isSoloProductLite  = require 'app/util/issoloproductlite'
KDNotificationView = kd.NotificationView

hiddenSectionsForSolo = [
  'Referral'
  'Billing'
]


handleSection = (path, callback) ->

  { appManager, router } = kd.singletons
  unless appManager.getFrontApp()
    appManager.once 'AppIsBeingShown', -> router.handleRoute path
    router.handleRoute '/IDE'
  else appManager.open 'Account', callback

handle = (args, path) ->
  handleSection path, (app) -> app.openSection args.params.section, args.query

module.exports = -> lazyrouter.bind 'account', (type, info, state, path, ctx) ->

  if info?.params?.section in hiddenSectionsForSolo
    if isSoloProductLite()
      return kd.singletons.router.handleRoute '/Account/Profile'

  switch type
    when 'profile'
      kd.singletons.router.handleRoute '/Account/Profile'
    when 'verified'
      new KDNotificationView { title: 'Thanks for verifying' }
      ctx.clear()
    when 'verification-failed'
      new KDNotificationView { title: 'Verification failed!' }
      ctx.clear()
    when 'referrer' then kd.singletons.router.handleRoute '/'
    when 'section' then handle info, path
