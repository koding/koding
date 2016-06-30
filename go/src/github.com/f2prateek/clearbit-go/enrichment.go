package clearbit

type Enrichment interface {
	Combined(email string) (*CombinedResponse, error)
}

type CombinedResponse struct {
	Person  *Person  `json:"person"`
	Company *Company `json:"company"`
}

type Person struct {
	AboutMe *struct {
		Avatar *string `json:"avatar"`
		Bio    *string `json:"bio"`
		Handle *string `json:"handle"`
	} `json:"aboutme"`
	AngelList *struct {
		Avatar    *string `json:"avatar"`
		Bio       *string `json:"bio"`
		Blog      *string `json:"blog"`
		Followers *int    `json:"followers"`
		Handle    *string `json:"handle"`
		Site      *string `json:"site"`
	} `json:"angellist"`
	Avatar     *string `json:"avatar"`
	Bio        *string `json:"bio"`
	Email      *string `json:"email"`
	Employment *struct {
		Domain *interface{} `json:"domain"`
		Name   *string      `json:"name"`
		Title  *string      `json:"title"`
	} `json:"employment"`
	Facebook *struct {
		Handle *string `json:"handle"`
	} `json:"facebook"`
	Foursquare *struct {
		Handle *string `json:"handle"`
	} `json:"foursquare"`
	Fuzzy  *bool   `json:"fuzzy"`
	Gender *string `json:"gender"`
	Geo    *struct {
		City        *string  `json:"city"`
		Country     *string  `json:"country"`
		CountryCode *string  `json:"countryCode"`
		Lat         *float64 `json:"lat"`
		Lng         *float64 `json:"lng"`
		State       *string  `json:"state"`
		StateCode   *string  `json:"stateCode"`
	} `json:"geo"`
	Github *struct {
		Avatar    *string `json:"avatar"`
		Blog      *string `json:"blog"`
		Company   *string `json:"company"`
		Followers *int    `json:"followers"`
		Following *int    `json:"following"`
		Handle    *string `json:"handle"`
		ID        *int    `json:"id"`
	} `json:"github"`
	GooglePlus *struct {
		Handle *string `json:"handle"`
	} `json:"googleplus"`
	Gravatar *struct {
		Avatar  *string `json:"avatar"`
		Avatars *[]struct {
			Type *string `json:"type"`
			URL  *string `json:"url"`
		} `json:"avatars"`
		Handle *string `json:"handle"`
		Urls   *[]struct {
			Title *string `json:"title"`
			Value *string `json:"value"`
		} `json:"urls"`
	} `json:"gravatar"`
	ID       *string `json:"id"`
	Linkedin *struct {
		Handle *string `json:"handle"`
	} `json:"linkedin"`
	Location *string `json:"location"`
	Name     *struct {
		FamilyName *string `json:"familyName"`
		FullName   *string `json:"fullName"`
		GivenName  *string `json:"givenName"`
	} `json:"name"`
	Site    *string `json:"site"`
	Twitter *struct {
		Avatar    *string `json:"avatar"`
		Bio       *string `json:"bio"`
		Followers *int    `json:"followers"`
		Following *int    `json:"following"`
		Handle    *string `json:"handle"`
		ID        *int    `json:"id"`
		Location  *string `json:"location"`
		Site      *string `json:"site"`
	} `json:"twitter"`
}

type Company struct {
	AngelList *struct {
		BlogURL     *string `json:"blogUrl"`
		Description *string `json:"description"`
		Followers   *int    `json:"followers"`
		Handle      *string `json:"handle"`
		ID          *int    `json:"id"`
	} `json:"angellist"`
	Crunchbase *struct {
		Handle *string `json:"handle"`
	} `json:"crunchbase"`
	Description   *string        `json:"description"`
	Domain        *string        `json:"domain"`
	DomainAliases *[]interface{} `json:"domainAliases"`
	EmailProvider *bool          `json:"emailProvider"`
	Facebook      *struct {
		Handle *string `json:"handle"`
	} `json:"facebook"`
	FoundedDate *string `json:"foundedDate"`
	Geo         *struct {
		City         *string      `json:"city"`
		Country      *string      `json:"country"`
		CountryCode  *string      `json:"countryCode"`
		Lat          *float64     `json:"lat"`
		Lng          *float64     `json:"lng"`
		PostalCode   *string      `json:"postalCode"`
		State        *string      `json:"state"`
		StateCode    *string      `json:"stateCode"`
		StreetName   *string      `json:"streetName"`
		StreetNumber *string      `json:"streetNumber"`
		SubPremise   *interface{} `json:"subPremise"`
	} `json:"geo"`
	ID        *string `json:"id"`
	LegalName *string `json:"legalName"`
	Linkedin  *struct {
		Handle *string `json:"handle"`
	} `json:"linkedin"`
	Location *string `json:"location"`
	Logo     *string `json:"logo"`
	Metrics  *struct {
		AlexaGlobalRank *int         `json:"alexaGlobalRank"`
		AlexaUsRank     *int         `json:"alexaUsRank"`
		Employees       *int         `json:"employees"`
		GoogleRank      *int         `json:"googleRank"`
		MarketCap       *interface{} `json:"marketCap"`
		Raised          *int         `json:"raised"`
	} `json:"metrics"`
	Name  *string `json:"name"`
	Phone *string `json:"phone"`
	Site  *struct {
		H1              *interface{} `json:"h1"`
		MetaAuthor      *interface{} `json:"metaAuthor"`
		MetaDescription *interface{} `json:"metaDescription"`
		Title           *interface{} `json:"title"`
		URL             *string      `json:"url"`
	} `json:"site"`
	Tags    *[]string `json:"tags"`
	Tech    *[]string `json:"tech"`
	Twitter *struct {
		Avatar    *string `json:"avatar"`
		Bio       *string `json:"bio"`
		Followers *int    `json:"followers"`
		Following *int    `json:"following"`
		Handle    *string `json:"handle"`
		ID        *string `json:"id"`
		Location  *string `json:"location"`
		Site      *string `json:"site"`
	} `json:"twitter"`
	Type *string `json:"type"`
	URL  *string `json:"url"`
}
