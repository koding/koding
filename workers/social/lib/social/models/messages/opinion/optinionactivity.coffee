CActivity = require '../../activity'

module.exports = class COpinionActivity extends CActivity

  @share()

  @set
    encapsulatedBy  : CActivity
    schema          : CActivity.schema
    relationships   :
      subject       :
        targetType  : "JOpinion"
        as          : 'opinion'