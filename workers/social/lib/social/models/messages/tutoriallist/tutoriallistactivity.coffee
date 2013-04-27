CActivity = require '../../activity'

module.exports = class CTutorialListActivity extends CActivity

  @trait __dirname, '../../../traits/grouprelated'
  
  @share()

  @set
    encapsulatedBy  : CActivity
    sharedMethods   : CActivity.sharedMethods
    schema          : CActivity.schema
    relationships   :
      subject       :
        targetType  : "JTutorialList"
        as          : 'content'