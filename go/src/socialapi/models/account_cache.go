package models

import "fmt"

var (
	accountCache map[int64]*Account
)

func init() {
	accountCache = make(map[int64]*Account)
}

func FetchAccountOldIdByIdFromCache(id int64) (string, error) {
	if a, ok := accountCache[id]; ok && a != nil {
		return a.OldId, nil
	}

	account, err := FetchAccountById(id)
	if err != nil {
		return "", err
	}

	accountCache[id] = account
	return account.OldId, nil
}

func FetchAccountFromCache(id int64) (*Account, error) {
	if a, ok := accountCache[id]; ok && a != nil {
		return a, nil
	}

	account, err := FetchAccountById(id)
	if err != nil {
		return nil, err
	}

	accountCache[id] = account
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
