package proxyconfig

import (
	"fmt"
	"koding/kontrol/kontrolproxy/models"
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

	_, err = p.Collection["domainstats"].Upsert(bson.M{"domainname": domainname}, domainStat)
	if err != nil {
		return err
	}

	return nil
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

	_, err = p.Collection["domainstats"].Upsert(bson.M{"domainname": domainname}, domainStat)
	if err != nil {
		return err
	}
	return nil
}

func (p *ProxyConfiguration) DeleteDomainStat(domainname string) error {
	err := p.Collection["domainstats"].Remove(bson.M{"domainname": domainname})
	if err != nil {
		return err
	}
	return nil
}

func (p *ProxyConfiguration) GetDomainStat(domainname string) (models.DomainStat, error) {
	domainstat := models.DomainStat{}
	err := p.Collection["domainstats"].Find(bson.M{"domainname": domainname}).One(&domainstat)
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
	iter := p.Collection["domainstats"].Find(nil).Iter()
	for iter.Next(&domainstat) {
		domainstats = append(domainstats, domainstat)
	}

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

	_, err = p.Collection["proxystats"].Upsert(bson.M{"proxyname": proxyname}, proxyStat)
	if err != nil {
		return err
	}
	return nil
}

func (p *ProxyConfiguration) DeleteProxyStat(proxyname string) error {
	err := p.Collection["proxystats"].Remove(bson.M{"proxyname": proxyname})
	if err != nil {
		return err
	}
	return nil
}

func (p *ProxyConfiguration) GetProxyStat(proxyname string) (models.ProxyStat, error) {
	proxystat := models.ProxyStat{}
	err := p.Collection["proxystats"].Find(bson.M{"proxyname": proxyname}).One(&proxystat)
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
	iter := p.Collection["proxystats"].Find(nil).Iter()
	for iter.Next(&proxystat) {
		proxystats = append(proxystats, proxystat)
	}

	return proxystats
}
