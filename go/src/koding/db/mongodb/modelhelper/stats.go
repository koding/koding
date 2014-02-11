package modelhelper

import (
	"fmt"
	"koding/db/models"
	"strconv"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

func NewDomainDenied(ip, country, reason string) *models.DomainDenied {
	return &models.DomainDenied{
		IP:       ip,
		Country:  country,
		Reason:   reason,
		DeniedAt: time.Now(),
	}
}

func NewDomainStat(name string) *models.DomainStat {
	return &models.DomainStat{
		Id:           bson.NewObjectId(),
		Domainname:   name,
		RequestsHour: make(map[string]int),
		Denied:       make([]models.DomainDenied, 0),
	}
}

func NewProxyStat(name string) *models.ProxyStat {
	return &models.ProxyStat{
		Id:           bson.NewObjectId(),
		Proxyname:    name,
		Country:      make(map[string]int),
		RequestsHour: make(map[string]int),
	}
}

func AddDomainDenied(domainname, ip, country, reason string) error {
	domainStat, err := GetDomainStat(domainname)
	if err != nil {
		return err
	}

	if domainStat.Domainname == "" {
		domainStat = *NewDomainStat(domainname)
	}

	domainStat.Denied = append(domainStat.Denied, *NewDomainDenied(ip, country, reason))

	query := func(c *mgo.Collection) error {
		_, err := c.Upsert(bson.M{"domainname": domainname}, domainStat)
		return err
	}

	return Mongo.Run("jDomainStats", query)
}

func AddDomainRequests(domainname string) error {
	domainStat, err := GetDomainStat(domainname)
	if err != nil {
		return err
	}

	if domainStat.Domainname == "" {
		domainStat = *NewDomainStat(domainname)
	}

	nowHour := strconv.Itoa(time.Now().Hour()) + ":00"
	_, ok := domainStat.RequestsHour[nowHour]
	if !ok {
		domainStat.RequestsHour[nowHour] = 1
	} else {
		domainStat.RequestsHour[nowHour]++
	}

	query := func(c *mgo.Collection) error {
		_, err := c.Upsert(bson.M{"domainname": domainname}, domainStat)
		return err
	}

	return Mongo.Run("jDomainStats", query)
}

func DeleteDomainStat(domainname string) error {
	query := func(c *mgo.Collection) error {
		return c.Remove(bson.M{"domainname": domainname})
	}

	return Mongo.Run("jDomainStats", query)
}

func GetDomainStat(domainname string) (models.DomainStat, error) {
	domainstat := models.DomainStat{}
	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"domainname": domainname}).One(&domainstat)
	}

	err := Mongo.Run("jDomainStats", query)
	if err != nil {
		if err.Error() == "not found" {
			return domainstat, nil //return empty struct
		}
		return domainstat, fmt.Errorf("no stat for domain %s exist (error %s).", domainname, err.Error())
	}

	return domainstat, nil
}

func GetDomainStats() []models.DomainStat {
	domainstat := models.DomainStat{}
	domainstats := make([]models.DomainStat, 0)

	query := func(c *mgo.Collection) error {
		iter := c.Find(nil).Iter()
		for iter.Next(&domainstat) {
			domainstats = append(domainstats, domainstat)
		}

		return nil
	}

	Mongo.Run("jDomainStats", query)
	return domainstats
}

func AddProxyStat(proxyname, country string) error {
	proxyStat, err := GetProxyStat(proxyname)
	if err != nil {
		return err
	}

	if proxyStat.Proxyname == "" {
		proxyStat = *NewProxyStat(proxyname)
	}

	nowHour := strconv.Itoa(time.Now().Hour()) + ":00"
	_, ok := proxyStat.RequestsHour[nowHour]
	if !ok {
		proxyStat.RequestsHour[nowHour] = 1
	} else {
		proxyStat.RequestsHour[nowHour]++
	}

	if country != "" {
		_, ok = proxyStat.Country[country]
		if !ok {
			proxyStat.Country[country] = 1
		} else {
			proxyStat.Country[country]++
		}
	}

	query := func(c *mgo.Collection) error {
		_, err = c.Upsert(bson.M{"proxyname": proxyname}, proxyStat)
		return err
	}

	return Mongo.Run("jProxyStats", query)
}

func DeleteProxyStat(proxyname string) error {
	query := func(c *mgo.Collection) error {
		return c.Remove(bson.M{"proxyname": proxyname})
	}

	return Mongo.Run("jProxyStats", query)
}

func GetProxyStat(proxyname string) (models.ProxyStat, error) {
	proxystat := models.ProxyStat{}

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"proxyname": proxyname}).One(&proxystat)
	}

	err := Mongo.Run("jProxyStats", query)
	if err != nil {
		if err.Error() == "not found" {
			return proxystat, nil //return empty struct
		}
		return proxystat, fmt.Errorf("no stat for proxy %s exist (error %s).", proxyname, err.Error())
	}

	return proxystat, nil
}

func GetProxyStats() []models.ProxyStat {
	proxystat := models.ProxyStat{}
	proxystats := make([]models.ProxyStat, 0)

	query := func(c *mgo.Collection) error {
		iter := c.Find(nil).Iter()
		for iter.Next(&proxystat) {
			proxystats = append(proxystats, proxystat)
		}
		return nil
	}

	Mongo.Run("jProxyStats", query)
	return proxystats
}
