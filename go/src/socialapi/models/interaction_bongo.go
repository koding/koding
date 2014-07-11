package models


func (i *Interaction) BeforeCreate() error {
	return i.MarkIfExempt()
}

func (i *Interaction) BeforeUpdate() error {
	return i.MarkIfExempt()
}

func (i *Interaction) AfterCreate() {
	bongo.B.AfterCreate(i)
}

func (i *Interaction) AfterUpdate() {
	bongo.B.AfterUpdate(i)
}

func (i Interaction) AfterDelete() {
	bongo.B.AfterDelete(i)
}

func (i Interaction) GetId() int64 {
	return i.Id
}

func (i Interaction) TableName() string {
	return "api.interaction"
}

func NewInteraction() *Interaction {
	return &Interaction{}
}

func (i *Interaction) One(q *bongo.Query) error {
	return bongo.B.One(i, i, q)
}

func (i *Interaction) ById(id int64) error {
	return bongo.B.ById(i, id)
}

func (i *Interaction) Create() error {
	return bongo.B.Create(i)
}

func (i *Interaction) Update() error {
	return bongo.B.Update(i)
}

func (i *Interaction) Some(data interface{}, q *bongo.Query) error {
	return bongo.B.Some(i, data, q)
}