package proxyconfig

import (
	"fmt"
	"koding/kontrol/kontrolproxy/models"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"strconv"
	"time"
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

func (p *ProxyConfiguration) AddDomainDenied(domainname, ip, country, reason string) error {
	domainStat, err := p.GetDomainStat(domainname)
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

	return p.RunCollection("jDomainStats", query)
}

func (p *ProxyConfiguration) AddDomainRequests(domainname string) error {
	domainStat, err := p.GetDomainStat(domainname)
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

	return p.RunCollection("jDomainStats", query)
}

func (p *ProxyConfiguration) DeleteDomainStat(domainname string) error {
	query := func(c *mgo.Collection) error {
		return c.Remove(bson.M{"domainname": domainname})
	}

	return p.RunCollection("jDomainStats", query)
}

func (p *ProxyConfiguration) GetDomainStat(domainname string) (models.DomainStat, error) {
	domainstat := models.DomainStat{}
	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"domainname": domainname}).One(&domainstat)
	}

	err := p.RunCollection("jDomainStats", query)
	if err != nil {
		if err.Error() == "not found" {
			return domainstat, nil //return empty struct
		}
		return domainstat, fmt.Errorf("no stat for domain %s exist (error %s).", domainname, err.Error())
	}

	return domainstat, nil
}

func (p *ProxyConfiguration) GetDomainStats() []models.DomainStat {
	domainstat := models.DomainStat{}
	domainstats := make([]models.DomainStat, 0)

	query := func(c *mgo.Collection) error {
		iter := c.Find(nil).Iter()
		for iter.Next(&domainstat) {
			domainstats = append(domainstats, domainstat)
		}

		return nil
	}

	p.RunCollection("jDomainStats", query)
	return domainstats
}

func (p *ProxyConfiguration) AddProxyStat(proxyname, country string) error {
	proxyStat, err := p.GetProxyStat(proxyname)
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

	return p.RunCollection("jProxyStats", query)
}

func (p *ProxyConfiguration) DeleteProxyStat(proxyname string) error {
	query := func(c *mgo.Collection) error {
		return c.Remove(bson.M{"proxyname": proxyname})
	}

	return p.RunCollection("jProxyStats", query)
}

func (p *ProxyConfiguration) GetProxyStat(proxyname string) (models.ProxyStat, error) {
	proxystat := models.ProxyStat{}

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"proxyname": proxyname}).One(&proxystat)
	}

	err := p.RunCollection("jProxyStats", query)
	if err != nil {
		if err.Error() == "not found" {
			return proxystat, nil //return empty struct
		}
		return proxystat, fmt.Errorf("no stat for proxy %s exist (error %s).", proxyname, err.Error())
	}

	return proxystat, nil
}

func (p *ProxyConfiguration) GetProxyStats() []models.ProxyStat {
	proxystat := models.ProxyStat{}
	proxystats := make([]models.ProxyStat, 0)

	query := func(c *mgo.Collection) error {
		iter := c.Find(nil).Iter()
		for iter.Next(&proxystat) {
			proxystats = append(proxystats, proxystat)
		}
		return nil
	}

	p.RunCollection("jProxyStats", query)
	return proxystats
}
