CActivity = require '../../activity'

module.exports = class CLinkActivity extends CActivity

  @share()

  @set
    encapsulatedBy  : CActivity
    sharedMethods   : CActivity.sharedMethods
    schema          : CActivity.schema
    relationships   :
      subject       :
        targetType  : 'JLink'
        as          : 'content'
