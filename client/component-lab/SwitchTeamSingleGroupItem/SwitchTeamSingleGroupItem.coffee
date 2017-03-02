{ PropTypes } = React = require 'react'
{ Row, Col } = require 'react-flexbox-grid'

Label = require 'lab/Text/Label'
globals = require 'globals'

styles = require './SwitchTeamSingleGroupItem.stylus'


SwitchTeamSingleGroupItem = ({ group }) ->

  <div className={styles.singlegroupinfo}>
    <Row>
      <Col md={2}><GroupLogo logo={group.customize?.logo} /></Col>
      <Col md={7}><GroupName slug={group.slug} /></Col>
      <Col md={3}><ButtonAction group={group} /></Col>
    </Row>
  </div>


GroupLogo = ({ logo }) ->

  <div className={styles.teamlogo}>
  {
    if logo
      <img src={logo} />
    else
      <div className={styles.defaultTeamLogo} />
  }
  </div>


GroupName = ({ slug }) ->

  <div className={styles.groupname}>
    <Label>
      {slug}
    </Label>
  </div>


ButtonAction = ({ group }) ->

  { slug, invitationCode, jwtToken } = group

  hostname = globals.config.domains.main
  domain   = if slug is 'koding' then hostname else "#{slug}.#{hostname}"

  actionTitle    = if invitationCode then 'Join' else 'Switch'
  actionLink     = if invitationCode
  then "//#{domain}/Invitation/#{encodeURIComponent invitationCode}"
  else "//#{domain}/-/loginwithtoken?token=#{jwtToken}"

  actionCssClass = "GenericButton #{styles.action}"
  actionCssClass += " #{styles.join}"  if invitationCode

  <a className={actionCssClass} href={actionLink} target="_self" > {actionTitle} </a>


SwitchTeamSingleGroupItem.propTypes =
  group: PropTypes.object.isRequired


SwitchTeamSingleGroupItem.defaultProps =
  groups: {}


module.exports = SwitchTeamSingleGroupItem
