_              = require 'lodash'
ReactComponent = require 'react/lib/ReactComponent'

# the reason we are using this instead of `kd.Object` is because kd.Object
# extends from EventEmitter and has extra functionality that we don't need to
# extract. This is a pure KDObject with `bound` and `lazyBound` types of
# methods.
{ KDObject }   = require 'kdf-core'


module.exports = class KDReactComponent extends ReactComponent

  _.extend @prototype, KDObject.prototype

  constructor: (props) ->

    # first call KDObject constructor.
    KDObject.call this, props

    super props


