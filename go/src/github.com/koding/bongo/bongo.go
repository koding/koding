package bongo

import "github.com/jinzhu/gorm"

type EventBus interface {
	Connect() error
	Close() error
	Publish(messageType string, data []byte) error
}

var B *Bongo

type Bongo struct {
	Broker EventBus
	DB     *gorm.DB
}

func New(b EventBus, db *gorm.DB) *Bongo {
	return &Bongo{
		Broker: b,
		DB:     db,
	}
}

func (b *Bongo) Connect() error {
	if err := b.Broker.Connect(); err != nil {
		return err
	}
	B = b
	// todo add gorm Connect()
	return nil
}

func (b *Bongo) Close() error {
	if err := b.Broker.Close(); err != nil {
		return err
	}
	// todo add gorm Close()
	return nil
}
