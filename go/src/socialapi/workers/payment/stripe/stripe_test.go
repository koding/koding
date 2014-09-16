package stripe

import (
	"testing"

	"socialapi/workers/common/runner"

	. "github.com/smartystreets/goconvey/convey"
	"github.com/stripe/stripe-go"
	stripeCustomer "github.com/stripe/stripe-go/customer"
	stripePlan "github.com/stripe/stripe-go/plan"
	stripeSub "github.com/stripe/stripe-go/sub"
)

func init() {
	r := runner.New("stripetest")
	if err := r.Init(); err != nil {
		panic(err)
	}
}

//----------------------------------------------------------
// Customer
//----------------------------------------------------------

func TestCreateAndFindCustomer(t *testing.T) {
	Convey("Given a description (id) and email", t, func() {
		desc, email := "indianajones", "indianajones@gmail.com"

		cust, err := CreateCustomer(desc, email)
		So(err, ShouldBeNil)

		Convey("Then it should create an customer in Stripe", func() {
			custFromStripe, err := stripeCustomer.Get(cust.ProviderCustomerId, nil)

			So(err, ShouldBeNil)
			So(custFromStripe.Id, ShouldEqual, cust.ProviderCustomerId)
		})

		Convey("Then it should save customer", func() {
			customerModel, err := FindCustomerByUsername(desc)

			So(err, ShouldBeNil)
			So(customerModel, ShouldNotBeNil)

			So(customerModel.Username, ShouldEqual, desc)
		})
	})
}

//----------------------------------------------------------
// Plan
//----------------------------------------------------------

func TestCreateAndFindPlan(t *testing.T) {
	Convey("Given default plans object", t, func() {
		err := CreateDefaultPlans()
		So(err, ShouldBeNil)

		Convey("Then it should create the plans in Stripe", func() {
			for plan_name, _ := range DefaultPlans {
				_, err := stripePlan.Get(plan_name, nil)
				So(err, ShouldBeNil)
			}
		})

		Convey("Then it should save the plans", func() {
			for plan_name, _ := range DefaultPlans {
				planModel, err := FindPlanByName(plan_name)

				So(err, ShouldBeNil)
				So(planModel, ShouldNotBeNil)

				So(planModel.Name, ShouldEqual, plan_name)
			}
		})
	})
}

//----------------------------------------------------------
// Subscription
//----------------------------------------------------------

func TestCreateAndFindSubscription(t *testing.T) {
	Convey("Given plan and customer id", t, func() {
		planModel, err := FindPlanByName("free_month")
		So(err, ShouldBeNil)
		So(planModel.ProviderPlanId, ShouldNotEqual, "")

		desc, email := "indianajones", "indianajones@gmail.com"
		customerModel, err := CreateCustomer(desc, email)
		So(err, ShouldBeNil)

		subModel, err := CreateSubscription(planModel, customerModel)
		So(err, ShouldBeNil)

		Convey("Then it should create subscription in Stripe", func() {
			subParams := &stripe.SubParams{
				Customer: customerModel.ProviderCustomerId,
				Plan:     planModel.ProviderPlanId,
			}

			s, err := stripeSub.Get(subModel.ProviderSubscriptionId, subParams)

			So(err, ShouldBeNil)
			So(s.Id, ShouldEqual, subModel.ProviderSubscriptionId)
		})
	})
}
