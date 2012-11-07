CActivity = require '../../activity'

module.exports = class CTutorialListActivity extends CActivity

  @share()

  @set
    encapsulatedBy  : CActivity
    sharedMethods   : CActivity.sharedMethods
    schema          : CActivity.schema
    relationships   :
      subject       :
        targetType  : "JTutorialList"
        as          : 'content'