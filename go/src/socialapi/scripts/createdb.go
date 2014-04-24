package main

import (
	"flag"
	"fmt"
	"socialapi/config"
	"socialapi/db"
	"socialapi/models"
	"socialapi/workers/helper"
)

var (
	flagProfile = flag.String("c", "", "Configuration profile from file")
	flagDebug   = flag.Bool("d", false, "Debug mode")
)

func main() {
	flag.Parse()
	if *flagProfile == "" {
		fmt.Println("Please define config file with -c", "Exiting...")
		return
	}

	conf := config.MustRead(*flagProfile)
	// create logger for our package
	log := helper.CreateLogger("DB Creation Script", *flagDebug)

	helper.MustInitBongo(conf, log)
	db.DB.LogMode(true)
	db.DB.Exec("drop table api.channel_message_list;")
	db.DB.Exec("drop table api.channel_message;")
	db.DB.Exec("drop table api.message_reply;")
	db.DB.Exec("drop table api.channel_participant;")
	db.DB.Exec("drop table api.channel;")
	db.DB.Exec("drop table api.interaction;")
	db.DB.Exec("drop table api.account;")

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
