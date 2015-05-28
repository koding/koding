package gather

import "koding/db/models"

type Exporter interface {
	SendResult(*models.GatherStat) error
	SendError(*models.GatherError) error
}
