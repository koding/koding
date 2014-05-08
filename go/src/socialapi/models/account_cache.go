package models

import "fmt"

var (
	accountCache map[int64]string
)

func init() {
	accountCache = make(map[int64]string)
	fmt.Println("hello")
}

func AccountOldIdById(id int64) (string, error) {
	if oldId, ok := accountCache[id]; ok {
		return oldId, nil
	}

	oldId, err := FetchOdlIdByAccountId(id)
	if err != nil {
		return "", err
	}

	accountCache[id] = oldId
	return oldId, nil

}
