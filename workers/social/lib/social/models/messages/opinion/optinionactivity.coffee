CActivity = require '../../activity'

module.exports = class COpinionActivity extends CActivity

  @trait __dirname, '../../../traits/grouprelated'

  @share()

  @set
    encapsulatedBy  : CActivity
    schema          : CActivity.schema
    sharedEvents    : CActivity.sharedEvents
    relationships   :
      subject       :
        targetType  : "JOpinion"
        as          : 'opinion'