getSessionToken=-> Cookies.get 'clientId'

{ logArgUri: apiEndpoint } = KD.config

KD.remote_log = new Bongo
  apiEndpoint     : apiEndpoint
  resourceName    : KD.config.logResourceName
  getUserArea     :-> KD.getSingleton('groupsController').getUserArea()
  getSessionToken : getSessionToken
  apiDescriptor   : REMOTE_LOGGING_API
