package rest

import (
	"fmt"
	"math/rand"
	"socialapi/models"
)

func testFollowingFeedOperations() {
	source := rand.Int63()
	target := rand.Int63()

	if err := FollowAccount(source, target); err != nil {
		fmt.Println("Err while following account, ", err)
	}
	if err := UnFollowAccount(source, target); err != nil {
		fmt.Println("Err while un-following account, ", err)
	}
}

func FollowAccount(sourceId, targetId int64) error {
	a := models.NewAccount()
	a.Id = sourceId

	url := fmt.Sprintf("/account/%d/follow", targetId)
	_, err := sendModel("POST", url, a)
	if err != nil {
		return err
	}

	return nil
}

func UnFollowAccount(sourceId, targetId int64) error {
	a := models.NewAccount()
	a.Id = sourceId

	url := fmt.Sprintf("/account/%d/unfollow", targetId)

	_, err := sendModel("POST", url, a)
	if err != nil {
		return err
	}

	return nil
}
