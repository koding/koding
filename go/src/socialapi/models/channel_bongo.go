package models


func (c Channel) GetId() int64 {
	return c.Id
}

func (c Channel) TableName() string {
	return "api.channel"
}

func (c *Channel) AfterCreate() {
	bongo.B.AfterCreate(c)
}

func (c *Channel) AfterUpdate() {
	bongo.B.AfterUpdate(c)
}

func (c Channel) AfterDelete() {
	bongo.B.AfterDelete(c)
}

func (c *Channel) BeforeCreate() error {
	c.CreatedAt = time.Now().UTC()
	c.UpdatedAt = time.Now().UTC()
	c.DeletedAt = ZeroDate()

	return c.MarkIfExempt()
}

func (c *Channel) BeforeUpdate() error {
	c.UpdatedAt = time.Now()

	return c.MarkIfExempt()
}


func (c *Channel) Update() error {
	if c.Name == "" || c.GroupName == "" {
		return fmt.Errorf("Validation failed %s - %s", c.Name, c.GroupName)
	}

	return bongo.B.Update(c)
}

func (c *Channel) Create() error {
	if c.Name == "" || c.GroupName == "" || c.TypeConstant == "" {
		return fmt.Errorf("Validation failed %s - %s -%s", c.Name, c.GroupName, c.TypeConstant)
	}

	// golang returns -1 if item not in the string
	if strings.Index(c.Name, " ") > -1 {
		return fmt.Errorf("Channel name %q has empty space in it", c.Name)
	}

	if c.TypeConstant == Channel_TYPE_GROUP ||
		c.TypeConstant == Channel_TYPE_FOLLOWERS /* we can add more types here */ {

		var selector map[string]interface{}
		switch c.TypeConstant {
		case Channel_TYPE_GROUP:
			selector = map[string]interface{}{
				"group_name":    c.GroupName,
				"type_constant": c.TypeConstant,
			}
		case Channel_TYPE_FOLLOWERS:
			selector = map[string]interface{}{
				"creator_id":    c.CreatorId,
				"type_constant": c.TypeConstant,
			}
		}

		// if err is nil
		// it means we already have that channel
		err := c.One(bongo.NewQS(selector))
		if err == nil {
			return nil
			// return fmt.Errorf("%s typed channel is already created before for %s group", c.TypeConstant, c.GroupName)
		}

		if err != bongo.RecordNotFound {
			return err
		}

	}

	return bongo.B.Create(c)
}

func (c *Channel) Delete() error {
	return bongo.B.Delete(c)
}

func (c *Channel) ById(id int64) error {
	return bongo.B.ById(c, id)
}

func (c *Channel) One(q *bongo.Query) error {
	return bongo.B.One(c, c, q)
}

func (c *Channel) Some(data interface{}, q *bongo.Query) error {
	return bongo.B.Some(c, data, q)
}
