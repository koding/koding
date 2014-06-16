package models

var (
	accountCache    map[int64]string
	oldAccountCache map[string]int64
)

func init() {
	accountCache = make(map[int64]string)
	oldAccountCache = make(map[string]int64)
}

func AccountOldIdById(id int64) (string, error) {
	if oldId, ok := accountCache[id]; ok {
		return oldId, nil
	}

	oldId, err := FetchOldIdByAccountId(id)
	if err != nil {
		return "", err
	}

	accountCache[id] = oldId
	return oldId, nil
}

func AccountOldsIdByIds(ids []int64) ([]string, error) {
	oldIds := make([]string, len(ids))
	if len(oldIds) == 0 {
		return oldIds, nil
	}

	for i, id := range ids {
		oldId, err := AccountOldIdById(id)
		if err != nil {
			return oldIds, err
		}
		oldIds[i] = oldId
	}

	return oldIds, nil
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
