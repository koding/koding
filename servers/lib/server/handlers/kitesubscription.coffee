koding  = require './../bongo'

module.exports = (req, res) ->

  { kiteToken, user, groupId } = req.params
  { JAccount, JKite, JGroup }  = koding.models

  return res.status(401).send { err: "TOKEN_REQUIRED"     } unless kiteToken
  return res.status(401).send { err: "USERNAME_REQUIRED"  } unless user
  return res.status(401).send { err: "GROUPNAME_REQUIRED" } unless groupId

  JKite.one kiteCode: kiteToken, (err, kite) ->
    return res.status(401).send { err: "KITE_NOT_FOUND" }  if err or not kite

    JAccount.one { "profile.nickname": user }, (err, account) ->
      return res.status(401).send err: "USER_NOT_FOUND"  if err or not account

      JGroup.one { "_id": groupId }, (err, group) =>
        return res.status(401).send err: "GROUP_NOT_FOUND"  if err or not group

        group.isMember account, (err, isMember) =>
          return res.status(401).send err: "NOT_A_MEMBER_OF_GROUP"  if err or not isMember

          kite.fetchPlans (err, plans) ->
            return res.status(401).send err: "KITE_HAS_NO_PLAN"  if err or not plans

            planMap = {}
            planMap[plan.planCode] = plan  for plan in plans

            kallback = (err, subscriptions) ->
              return res.status(401).send err: "NO_SUBSCRIPTION"  if err or not subscriptions

              freeSubscription = null
              paidSubscription = null
              for item in subscriptions
                if "nosync" in item.tags
                  freeSubscription = item
                else
                  paidSubscription = item

              subscription = paidSubscription or freeSubscription
              if subscription and plan = planMap[subscription.planCode]
                  res.status(200).send planId: plan.planCode, planName: plan.title
              else
                res.status(401).send err: "NO_SUBSCRIPTION"

            if group.slug is "koding"
              targetOptions =
                selector    :
                  tags      : "vm"
                  planCode  : $in: (plan.planCode for plan in plans)
              account.fetchSubscriptions null, {targetOptions}, kallback
            else
              group.fetchSubscriptions kallback