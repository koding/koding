class AccountResource extends Resource
  constructor: ->
    super bongo.api.JAccount
  
ResourceManager.register 'account', AccountResource