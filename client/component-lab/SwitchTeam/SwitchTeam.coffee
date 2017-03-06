{ PropTypes } = React = require 'react'

SwitchTeamSingleGroupItem = require 'lab/SwitchTeamSingleGroupItem'

Label = require 'lab/Text/Label'
styles = require './SwitchTeam.stylus'

SwitchTeam = ({ groups, isOwner }) ->

  optionCopy = "
    ... or you can switch to another team of yours
  "

  <div className={styles.switchteam}>
    <div className={styles.optiontext}>
      <Label>
        {optionCopy}
      </Label>
    </div>
    <div className={styles.groups}>
      { groups.map (group) -> <SwitchTeamSingleGroupItem key={group.slug} group={group} /> }
    </div>
  </div>


SwitchTeam.propTypes =
  groups: PropTypes.array


SwitchTeam.defaultProps =
  groups: []


module.exports = SwitchTeam
