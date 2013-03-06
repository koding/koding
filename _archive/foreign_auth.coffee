# class Foreign_auth
#   receiveForeignAuthUser : (action, user)->
#     modal = new KDModalView
#       title   : "#{user.authType.capitalize()}:"
#       content : "Do you want to <span style='color: green; font-size: 14pt;'>#{action}</span> your #{user.username} account from #{user.authType}?"
#       overlay : yes
#       buttons :
#         No      :
#           style     : "clean-red"
#           callback  : ()->
#             modal.destroy()
#         Yes     :
#           style     : "cupid-green"
#           callback  : ()=>
#             modal.destroy()
#             switch action
#               when 'login'
#                 KD.setAuthKey user.authKey
#                 site = KDObject::getSingleton("site")
#                 site.account?.destroy()
#                 KDObject::emptyDataCache
#                 site.persist
#                   action : "fetch"
#                   dataPath : "account"
#                 ,null, ()=>
#                   site.propagateEvent (KDEventType:"Data.account")
#                 new KDNotificationView
#                   type    : "tray"
#                   title   : "Successfully logged in!"
#                   duration: 1000
#               when 'register'
#                 {mainTabView} = @getSingleton('mainController')
#                 if mainTabView.getPaneByName('Register') is false
#                   mainTabView.createTabPane name : 'Register', null
#                 for pane in mainTabView.panes
#                   registerPane = pane if pane.name is "Register"
#                 for subView in registerPane.subViews
#                   registerPage = subView if subView instanceof PageRegister
#                 registerPage.onOAuthSucces user, user.authType
#                 KD.getSingleton('mainController').goToPage null,{pageName : "Register", appPath:"Register"}
#               when 'del'
#                 KDData::invokeServerSide
#                   deleteForeignProvider:
#                     params: {authType: user.authType}
#                     middleware: (err, params, result)=>
#                       if result.success
#                         new KDNotificationView
#                           type    : "tray"
#                           title    : "Successfully deleted #{user.authType} from you #{user.username} user!"
#                           duration : 3000
#                         KDView::handleEvent
#                           type         : "ProvidersChangedTrigger"
#                           authType     : user.authType
#                           authId       : user.authId
#                           user         : user
#                           action       : "deleted"
#                       else
#                         log "erorr", result.err
#               when 'add'
#                 KDData::invokeServerSide
#                   appendForeignProvider:
#                     params: user
#                     middleware: (err, params, result)=>
#                       if result.success
#                         new KDNotificationView
#                           type    : "tray"
#                           title    : "#{user.authType.capitalize()} successfully added to your #{user.username} user!"
#                           duration : 3000
#                         KDView::handleEvent
#                           type         : "ProvidersChangedTrigger"
#                           authType     : user.authType
#                           authId       : user.authId
#                           user         : user
#                           action       : "added"
#                       else
#                         log "erorr", result.err
#               when 'verify'
#                 KDView::handleEvent
#                   type         : "ProvidersChangedTrigger"
#                   authType     : user.authType
#                   authId       : user.authId
#                   user         : user
#                   action       : "verified"
#               when 'merge'
#                 log "mergeTrigger: merge accounts here"
#               when 'mountAdd'
#                 if user.authType is 'dropbox'
#                   KDView::handleEvent
#                     type : "DropboxMountAddTrigger"
#                     user : user
#               # when 'mountAdd'
#               else
#                 log "foreignProviderTrigger: unknown action = #{action}"


# @foreign_auth = new Foreign_auth()
