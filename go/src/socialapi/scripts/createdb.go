package main

import (
	"fmt"
	"socialapi/db"
	"socialapi/models"
)

func main() {
	db.DB.LogMode(true)
	db.DB.Exec("drop table channel_message_list;")
	db.DB.Exec("drop table channel_message;")
	db.DB.Exec("drop table message_reply;")
	db.DB.Exec("drop table channel_participant;")
	db.DB.Exec("drop table channel;")
	db.DB.Exec("drop table interaction;")
	db.DB.Exec("drop table account;")

	if err := db.DB.CreateTable(&models.ChannelMessage{}).Error; err != nil {
		panic(fmt.Sprintf("No error should happen when create table, but got %+v", err))
	}
	if err := db.DB.CreateTable(&models.MessageReply{}).Error; err != nil {
		panic(fmt.Sprintf("No error should happen when create table, but got %+v", err))
	}
	if err := db.DB.CreateTable(&models.Channel{}).Error; err != nil {
		panic(fmt.Sprintf("No error should happen when create table, but got %+v", err))
	}
	if err := db.DB.CreateTable(&models.ChannelMessageList{}).Error; err != nil {
		panic(fmt.Sprintf("No error should happen when create table, but got %+v", err))
	}
	if err := db.DB.CreateTable(&models.ChannelParticipant{}).Error; err != nil {
		panic(fmt.Sprintf("No error should happen when create table, but got %+v", err))
	}
	if err := db.DB.CreateTable(&models.Interaction{}).Error; err != nil {
		panic(fmt.Sprintf("No error should happen when create table, but got %+v", err))
	}
	if err := db.DB.CreateTable(&models.Account{}).Error; err != nil {
		panic(fmt.Sprintf("No error should happen when create table, but got %+v", err))
	}
}
