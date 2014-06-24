// rewrite this part with cache/memory
package models

import "fmt"

var (
	accountCache    map[int64]*Account
	oldAccountCache map[string]int64
)

func init() {
	// those are not thread safe!!!!
	accountCache = make(map[int64]*Account)
	oldAccountCache = make(map[string]int64)
}

func FetchAccountOldIdByIdFromCache(id int64) (string, error) {
	if a, ok := accountCache[id]; ok && a != nil {
		return a.OldId, nil
	}

	account, err := ResetAccountCache(id)

	return account.OldId, nil
}

func FetchAccountFromCache(id int64) (*Account, error) {
	if a, ok := accountCache[id]; ok && a != nil {
		return a, nil
	}

	return ResetAccountCache(id)
}

func ResetAccountCache(id int64) (*Account, error) {
	account, err := FetchAccountById(id)
	if err != nil {
		return nil, err
	}

	SetAccountToCache(account)

	return account, nil
}

func FetchAccountOldsIdByIdsFromCache(ids []int64) ([]string, error) {
	oldIds := make([]string, len(ids))
	if len(oldIds) == 0 {
		return oldIds, nil
	}

	for i, id := range ids {
		oldId, err := FetchAccountOldIdByIdFromCache(id)
		if err != nil {
			return oldIds, err
		}
		oldIds[i] = oldId
	}

	return oldIds, nil
}

func SetAccountToCache(a *Account) {
	if a == nil {
		return
	}

	if a.Id == 0 {
		fmt.Println("account id is empty")
		return
	}

	accountCache[a.Id] = a
}

func AccountIdByOldId(oldId, nick string) (int64, error) {
	if id, ok := oldAccountCache[oldId]; ok {
		return id, nil
	}

	a := NewAccount()
	a.OldId = oldId
	a.Nick = nick
	if err := a.FetchOrCreate(); err != nil {
		return 0, err
	}

	oldAccountCache[oldId] = a.Id

	return a.Id, nil
}
