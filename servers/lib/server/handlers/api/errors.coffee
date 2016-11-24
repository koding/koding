module.exports = {

  internalError                 :
    status                      : 500
    message                     : 'The server encountered an internal error.'
    code                        : 'InternalError'

  notImplementedError           :
    status                      : 501
    message                     : 'Request is not implemented yet.'
    code                        : 'NotImplementedError'

  invalidRequestDomain          :
    status                      : 400
    message                     : 'Request domain is not valid'
    code                        : 'InvalidRequestDomain'

  groupNotFound                 :
    status                      : 403
    message                     : 'The group of the given api token does not exist.'
    code                        : 'GroupNotFound'

  apiIsDisabled                 :
    status                      : 403
    message                     : 'Api usage for this group is disabled.'
    code                        : 'ApiIsDisabled'

  invalidApiToken               :
    status                      : 400
    message                     : 'Api token is invalid.'
    code                        : 'InvalidApiToken'

  unauthorizedRequest           :
    status                      : 401
    message                     : 'The request is unauthorized, a valid session or an api token is required.'
    code                        : 'UnauthorizedRequest'

  invalidInput                  :
    status                      : 400
    message                     : 'One of the request inputs is invalid.'
    code                        : 'InvalidInput'

  failedToCreateUser            :
    status                      : 500
    message                     : 'An error occurred, failed to create user.'
    code                        : 'FailedToCreateUser'

  failedToCreateSession         :
    status                      : 500
    message                     : 'An error occurred, failed to create user session. User may not be logged in.'
    code                        : 'FailedToCreateSession'

  usernameAlreadyExists         :
    status                      : 409
    message                     : 'This username is already in use, please try another one.'
    code                        : 'UsernameAlreadyExists'

  emailAlreadyExists            :
    status                      : 409
    message                     : 'This email is already in use, please try another one.'
    code                        : 'EmailAlreadyExists'

  invalidEmailDomain            :
    status                      : 400
    message                     : 'This email domain is not in allowed domains for this group.'
    code                        : 'InvalidEmailDomain'

  invalidUsername               :
    status                      : 400
    message                     : 'Given username is invalid.'
    code                        : 'InvalidUsername'

  notGroupMember                :
    status                      : 400
    message                     : 'User is not a member of the api token group.'
    code                        : 'NotGroupMember'

  ssoTokenFailedToParse         :
    status                      : 400
    message                     : 'The sso token in request could not be parsed.'
    code                        : 'SSOTokenFailedToParse'

  invalidSSOTokenPayload        :
    status                      : 400
    message                     : 'One of the required fields in payload is invalid'
    code                        : 'InvalidSSOTokenPayload'

  missingRequiredQueryParameter :
    status                      : 400
    message                     : 'A required query parameter was not specified for this request.'
    code                        : 'MissingRequiredQueryParameter'

  outOfRangeUsername            :
    status                      : 400
    message                     : 'Given username is out of range.'
    code                        : 'OutOfRangeUsername'

  outOfRangeSuggestedUsername   :
    status                      : 400
    message                     : 'Given suggested username is out of range.'
    code                        : 'OutOfRangeSuggestedUsername'

}
