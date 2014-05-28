getSessionToken=-> Cookies.get 'clientId'

{ logApiUri: apiEndpoint } = KD.config

KD.remoteLog = new Bongo
  apiEndpoint     : apiEndpoint
  resourceName    : KD.config.logResourceName
  getUserArea     :-> KD.getSingleton('groupsController').getUserArea()
  getSessionToken : getSessionToken
  apiDescriptor   : REMOTE_LOGGING_API
