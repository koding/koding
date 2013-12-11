class LoginAppsController extends AppController

  handler = (callback)->->
    unless KD.isLoggedIn()
      KD.singleton('appManager').open 'Login', (app)-> callback app
    else
      KD.getSingleton('router').handleRoute "/Activity"

  handleResetRoute = ({params:{token}})->
    KD.singleton('appManager').open 'Login', (app)=>
      if KD.isLoggedIn()
        KD.getSingleton('router').handleRoute "/Account/Profile?focus=password&token=#{token}"
      else
        app.getView().setCustomDataToForm('reset', {recoveryToken:token})
        app.getView().animateToForm('reset')

  #### Leaving it here incase we decide to have another beta: SA
  #handleFailureOfRestriction =->
    #KD.utils.defer -> new KDNotificationView title: "Login restricted"

  #handleRestriction = (handler) ->
    #({params: {token : token}})->
      #for url in ['localhost', 'https://koding.com'] when (new RegExp url).test window.location
        #return do handler()

      #return handleFailureOfRestriction()  unless token

      #KD.remote.api.JInvitation.byCodeForBeta token, (err, invite)->
        #if err or !invite?
          #return handleFailureOfRestriction()

        #do handler()
  ####

  KD.registerAppClass this,
    name                         : "Login"
    routes                       :
      #'/:name?/Login/:token?'    : handleRestriction (app)->
          #handler (app)-> app.getView().animateToForm 'login'
      '/:name?/Login/:token?'    : handler (app)-> app.getView().animateToForm 'login'
      '/:name?/Redeem'           : handler (app)-> app.getView().animateToForm 'redeem'
      '/:name?/Register/:token?' : handler (app)-> app.getView().animateToForm 'register'
      '/:name?/Recover'          : handler (app)-> app.getView().animateToForm 'recover'
      '/:name?/Reset'            : handler (app)-> app.getView().animateToForm 'reset'
      '/:name?/Reset/:token'     : handleResetRoute
      '/:name?/ResendToken'      : handler (app)-> app.getView().animateToForm 'resendEmail'
    hiddenHandle                 : yes
    behavior                     : 'application'
    # removed preCondition because Reset can be called while
    # current user logged-in status

  constructor:(options = {}, data)->

    options.view    = new LoginView
      testPath      : "landing-login"
    options.appInfo =
      name          : "Login"

    super options, data
