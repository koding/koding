React = require 'app/react'
Box = require 'lab/Box'
Button = require 'lab/Button'
generateClassName = require 'classnames'
formatMoney = require 'app/util/formatMoney'
styles = require './SupportPlan.stylus'

module.exports = class SupportPlan extends React.Component

  render: ->

    { name, price, period, type, features,
      onActivationButtonClick, contactUsLink, className } = @props

    className = generateClassName [
      styles.supportPlan
      type is 'active' and styles.active
      className
    ]

    boxType =  if type is 'active'
    then 'success'
    else 'default'

    <Box type={boxType} border={1} className={className}>
      <Info
        name={name}
        price={price}
        period={period} />
      <Features features={features} />
      <Action
        type={type}
        price={price}
        contactUsLink={contactUsLink or 'http://www.koding.com'}
        onClick={onActivationButtonClick} />
    </Box>


Info = (options) ->

  {name, price, period} = options
  priceView =  if price
  then <span className={styles.price}>{formatMoney price}</span>
  else <span className={styles.special}>Contact Us</span>

  <section className={styles.info}>
    <div className={styles.priceSegment}>
      <span className={styles.name}>{name}</span>
      {priceView}
      {
          <span className={styles.period}>/{period}</span>  if price and period
      }
    </div>
  </section>


Features = ({features}) ->

  <section className={styles.features}>
    {
      if features
        <ul>
          {
            features.map (feature, index) ->
              <li
                key={index}
                className={styles.feature}
                dangerouslySetInnerHTML={{__html: feature}} />
          }
        </ul>
    }
  </section>


Action = (options) ->

  {type, price, contactUsLink, onClick} = options
  action = switch type
    when 'active' then <span className={styles.planActive}>ACTIVE</span>
    when 'activation' then <ActivationButton
                              price={formatMoney price}
                              contactUsLink={contactUsLink}
                              onClick={onClick}/>
    when 'switch' then <SwitchableAction contactUsLink={contactUsLink} />
    else <a href={contactUsLink}><Button type='primary-1' size='medium' auto>CONTACT US</Button></a>

  className = generateClassName [
    styles.action
    type is 'switch' and styles.switchable
  ]

  <section className={className}>
    {action}
  </section>


ActivationButton = (options) ->

  {price, onClick, contactUsLink} = options
  activationButton = if price
  then <Button type='primary-1' size='medium' auto onClick={onClick}>ACTIVATE</Button>
  else <a href={contactUsLink}><Button type='primary-1' size='medium' auto>CONTACT US</Button></a>
  return activationButton


SwitchableAction = ({contactUsLink}) ->

  <div className={styles.switchableAction}>
    <span className={styles.switchableActionHeader}>CONTACT US</span>
    <p>Please <a href={contactUsLink}>contact us</a> to switch to this plan.</p>
  </div>
