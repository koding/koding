package models

import (
	"math/rand"
	"strconv"
	"time"

	"github.com/dchest/uniuri"
)

func RandomName() string {
	return uniuri.New()
}

func RandomGroupName() string {
	rand.Seed(time.Now().UnixNano())
	return "group" + strconv.FormatInt(rand.Int63(), 10)
}

func ZeroDate() time.Time {
	return time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC)
}
