module.exports = class OpaqueType
  constructor:(type)->
    konstructor = do Function "return function #{type}() {}"
    konstructor extends OpaqueType
    # override the instance with an instance of the subclass.
    # This is so developers can still use instanceof with opaque types.
    return konstructor

  @isOpaque =-> yes
