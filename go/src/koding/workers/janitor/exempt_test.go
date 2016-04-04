package main

import (
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/db/mongodb/modelhelper/modeltesthelper"
	"net/http"
	"net/http/httptest"
	"net/url"
	"socialapi/workers/payment/paymentapi"
	"testing"
	"time"

	"gopkg.in/mgo.v2/bson"

	. "github.com/smartystreets/goconvey/convey"
)

func TestIsUserPaid(t *testing.T) {
	Convey("Given user who is paid", t, func() {
		username := bson.NewObjectId().Hex()
		user, _, err := modeltesthelper.CreateUser(username)
		So(err, ShouldBeNil)

		Convey("Then it returns true if user is paid", func() {
			mux := http.NewServeMux()
			mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
				fmt.Fprint(w, `{"planTitle":"hobbyist"}`)
			})

			server := httptest.NewServer(mux)
			url, _ := url.Parse(server.URL)

			defer func() {
				server.Close()
			}()

			account, err := modelhelper.GetAccount(username)
			So(err, ShouldBeNil)

			paymentclient := paymentapi.New(url.String())
			isPaid, err := paymentclient.IsPaidAccount(account)
			So(err, ShouldBeNil)
			So(isPaid, ShouldBeTrue)
		})

		Convey("Then it returns false if user is free", func() {
			mux := http.NewServeMux()
			mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
				fmt.Fprint(w, `{"planTitle":"free"}`)
			})

			server := httptest.NewServer(mux)
			url, _ := url.Parse(server.URL)

			defer func() {
				server.Close()
			}()

			account, err := modelhelper.GetAccount(username)
			So(err, ShouldBeNil)

			paymentclient := paymentapi.New(url.String())

			no, err := paymentclient.IsPaidAccount(account)
			So(err, ShouldBeNil)
			So(no, ShouldBeFalse)
		})

		Reset(func() {
			deleteUserWithUsername(user)
		})
	})
}

func TestIsUserNotConfirmed(t *testing.T) {
	warning := &Warning{}

	Convey("Given user who is unconfirmed", t, func() {
		username := bson.NewObjectId().Hex()
		user := &models.User{
			ObjectId: bson.NewObjectId(),
			Name:     username,
			Status:   "unconfirmed",
			Email:    username + "@" + username + ".com",
		}

		err := modelhelper.CreateUser(user)
		So(err, ShouldBeNil)

		Convey("Then it returns true for 'not confirmed' exempt", func() {
			isConfirmed, err := IsUserNotConfirmedFn(user, warning)
			So(err, ShouldBeNil)
			So(isConfirmed, ShouldBeTrue)
		})

		Reset(func() {
			deleteUserWithUsername(user)
		})
	})
}

func TestIsUserVMsEmpty(t *testing.T) {
	warning := &Warning{}

	Convey("Given user who has no vms", t, func() {
		username := bson.NewObjectId().Hex()
		user, _, err := modeltesthelper.CreateUser(username)

		So(err, ShouldBeNil)
		Convey("Then it returns true for 'no vm' exempt", func() {
			noVms, err := IsUserVMsEmptyFn(user, warning)

			So(err, ShouldBeNil)
			So(noVms, ShouldBeTrue)
		})

		Reset(func() {
			deleteUserWithUsername(user)
		})
	})

	Convey("Given user who has vms", t, func() {
		user, err := createUserWithVM()
		So(err, ShouldBeNil)

		Convey("Then it returns false for 'no vm' exempt", func() {
			noVms, err := IsUserVMsEmptyFn(user, warning)

			So(err, ShouldBeNil)
			So(noVms, ShouldBeFalse)
		})

		Reset(func() {
			deleteUserWithUsername(user)
		})
	})

	Convey("Given user who has only managed vms", t, func() {
		user, err := createUserWithManagedVM()

		So(err, ShouldBeNil)
		Convey("Then it returns true for 'no vm' exempt", func() {
			noVms, err := IsUserVMsEmptyFn(user, warning)

			So(err, ShouldBeNil)
			So(noVms, ShouldBeTrue)
		})

		Reset(func() {
			deleteUserWithUsername(user)
		})
	})
}

func TestIsTooSoon(t *testing.T) {
	previous := &Warning{
		ID: "previous-testtoosoon",
	}

	warning := &Warning{
		ID: "testtoosoon",
		IntervalSinceLastWarning: time.Hour * 24 * 1,
		PreviousWarning:          previous,
	}

	Convey("Given user who is inactive and was warned yesterday", t, func() {
		user, err := createInactiveUserWithWarning(1, previous.ID)
		So(err, ShouldBeNil)

		Convey("Then it returns true for check", func() {
			tooSoon, err := IsTooSoonFn(user, warning)

			So(err, ShouldBeNil)
			So(tooSoon, ShouldBeTrue)

			Reset(func() {
				deleteUserWithUsername(user)
			})
		})
	})

	Convey("Given user who is inactive and was warned two days ago", t, func() {
		user, err := createInactiveUserWithWarning(1, previous.ID)
		So(err, ShouldBeNil)

		selector := bson.M{"username": user.Name}
		update := bson.M{
			"inactive.warnings": bson.M{
				previous.ID: timeNow().Add(-warning.IntervalSinceLastWarning * 2),
			},
		}

		err = modelhelper.UpdateUser(selector, update)
		So(err, ShouldBeNil)

		Convey("Then it returns false for check", func() {
			user, err := modelhelper.GetUser(user.Name)
			So(err, ShouldBeNil)

			tooSoon, err := IsTooSoonFn(user, warning)

			So(err, ShouldBeNil)
			So(tooSoon, ShouldBeFalse)
		})

		Reset(func() {
			deleteUserWithUsername(user)
		})
	})
}

func TestIsUserKodingEmployee(t *testing.T) {
	warning := &Warning{}

	Convey("Given user who does not have koding email", t, func() {
		username := bson.NewObjectId().Hex()
		user := &models.User{
			Name: username, ObjectId: bson.NewObjectId(), Status: "confirmed",
			Email: username + "@gmail.com",
		}

		err := modelhelper.CreateUser(user)
		So(err, ShouldBeNil)

		Convey("Then it returns true for check", func() {
			isEmployee, err := IsUserKodingEmployeeFn(user, warning)
			So(err, ShouldBeNil)
			So(isEmployee, ShouldBeFalse)
		})

		Reset(func() {
			deleteUserWithUsername(user)
		})
	})

	Convey("Given user who has koding email", t, func() {
		username := bson.NewObjectId().Hex()
		user := &models.User{
			Name: username, ObjectId: bson.NewObjectId(), Status: "confirmed",
			Email: username + "@koding.com",
		}

		err := modelhelper.CreateUser(user)
		So(err, ShouldBeNil)

		Convey("Then it returns true for check", func() {
			isEmployee, err := IsUserKodingEmployeeFn(user, warning)
			So(err, ShouldBeNil)
			So(isEmployee, ShouldBeTrue)
		})

		Reset(func() {
			deleteUserWithUsername(user)
		})
	})
}

func TestHasMultipleMembershipsFn(t *testing.T) {
	warning := &Warning{}

	Convey("Given a user", t, func() {
		username := bson.NewObjectId().Hex()
		user, acc, err := modeltesthelper.CreateUser(username)
		So(err, ShouldBeNil)
		So(user, ShouldNotBeNil)

		group, err := modeltesthelper.CreateGroup()
		So(err, ShouldBeNil)
		So(group, ShouldNotBeNil)

		group2, err := modeltesthelper.CreateGroup()
		So(err, ShouldBeNil)
		So(group, ShouldNotBeNil)

		Convey("Who is only one group member", func() {
			if err := addRelationship(acc.Id, group.Id, "admin"); err != nil {
				t.Error(err)
			}

			if err := addRelationship(acc.Id, group.Id, "member"); err != nil {
				t.Error(err)
			}

			Convey("Then it returns true when group is not koding", func() {
				has, err := HasMultipleMembershipsFn(user, warning)
				So(err, ShouldBeNil)
				So(has, ShouldBeTrue)
			})

			Convey("Then it returns false when group is koding", func() {
				groupName := kodingGroupName
				defer func() { kodingGroupName = groupName }() //be a good citizen
				kodingGroupName = group.Slug

				has, err := HasMultipleMembershipsFn(user, warning)
				So(err, ShouldBeNil)
				So(has, ShouldBeFalse)
			})

			Convey("Who is member of multiple group", func() {
				if err := addRelationship(acc.Id, group2.Id, "admin"); err != nil {
					t.Error(err)
				}

				Convey("Then it returns true for check", func() {
					groupName := kodingGroupName
					defer func() { kodingGroupName = groupName }() //be a good citizen
					kodingGroupName = group.Slug

					has, err := HasMultipleMembershipsFn(user, warning)
					So(err, ShouldBeNil)
					So(has, ShouldBeTrue)
				})

				Reset(func() {
					deleteUserWithUsername(user)
				})
			})
		})
	})

}

func addRelationship(accId, groupId bson.ObjectId, rel string) error {
	return modelhelper.AddRelationship(&models.Relationship{
		Id:         bson.NewObjectId(),
		TargetId:   accId,
		TargetName: "JAccount",
		SourceId:   groupId,
		SourceName: "JGroup",
		As:         "admin",
	})
}
