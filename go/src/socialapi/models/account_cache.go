package models

var (
	accountCache map[int64]string
)

func init() {
	accountCache = make(map[int64]string)
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
