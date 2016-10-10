package config

// Bucket is a configuration of a single bucket.
type Bucket struct {
	Environment []string `json:"environment"`
	Name        string   `json:"name"`
	Region      string   `json:"region"`
}

// Buckets describes all buckets and their configuration.
type Buckets map[string][]*Bucket

// ByEnv looks up a bucket by the given name and environment.
func (b Buckets) ByEnv(name, environment string) *Bucket {
	buckets, ok := b[name]
	if !ok {
		return nil
	}

	var bkt *Bucket

	for _, bucket := range buckets {
		if len(bucket.Environment) == 0 {
			bkt = bucket
			continue
		}

		for _, env := range bucket.Environment {
			switch env {
			case environment:
				return bucket
			case "development", "devmanaged":
				if bkt == nil {
					bkt = bucket
				}
			}
		}
	}

	return bkt
}

// merge merge two buckets, it prevents environments' uniqueness across
// different buckets.
func (b Buckets) merge(in Buckets) {
	for inname, inbuckets := range in {
		buckets, ok := b[inname]
		if !ok {
			// Add missing buckets to b.
			b[inname] = inbuckets
			continue
		}

		// Remove environments from buckets and add inbucket to the end.
		for _, inbucket := range inbuckets {
			for i := range buckets {
				buckets[i].Environment = removeStrings(buckets[i].Environment, inbucket.Environment...)
			}
			buckets = append(buckets, inbucket)
		}

		// Merge environments which have the same buckets.
		for i := 0; i < len(buckets); i++ {
			if buckets[i] == nil {
				continue
			}
			for j := i + 1; j < len(buckets); j++ {
				if buckets[j] == nil {
					continue
				}
				if buckets[i].Name == buckets[j].Name && buckets[i].Region == buckets[j].Region {
					buckets[i].Environment = append(buckets[i].Environment, buckets[j].Environment...)
					buckets[j] = nil
				}
			}
		}

		// Remove nil buckets or these with empty environments.
		var outbuckets []*Bucket
		for _, bucket := range buckets {
			if bucket != nil && len(bucket.Environment) != 0 {
				outbuckets = append(outbuckets, bucket)
			}
		}

		// Replace buckets.
		b[inname] = outbuckets
	}
}
