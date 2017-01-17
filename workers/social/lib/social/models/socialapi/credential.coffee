module.exports = class SocialCredential

  { secureRequest } = require './helper'

  @store     = secureRequest {
    fnName   : 'storeCredential'
    validate : ['pathName']
  }

  @get       = secureRequest {
    fnName   : 'getCredential'
    validate : ['pathName']
  }

  @delete    = secureRequest {
    fnName   : 'deleteCredential'
    validate : ['pathName']
  }
