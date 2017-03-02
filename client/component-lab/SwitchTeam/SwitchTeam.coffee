{ PropTypes } = React = require 'react'
{ Row, Col } = require 'react-flexbox-grid'

SwitchTeamSingleGroupItem = require 'lab/SwitchTeamSingleGroupItem'
Label = require 'lab/Text/Label'
styles = require './SwitchTeam.stylus'

SwitchTeam = ({ groups, isOwner }) ->

  optionCopy = "
    Other options: You can switch to one of the other teams,
    #{if isOwner then 'delete' else 'leave'} this team or delete your account
  "

  <div className={styles.switchteam}>
    <Row>
      <div className={styles.optiontext}>
        <Label>
          {optionCopy}
        </Label>
      </div>
    </Row>
    <div className={styles.groups}>
      { groups.map (group) -> <SwitchTeamSingleGroupItem key={group.slug} group={group} /> }
    </div>
  </div>


SwitchTeam.propTypes =
  groups: PropTypes.array


SwitchTeam.defaultProps =
  groups: []


module.exports = SwitchTeam
