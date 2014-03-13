package ldapserver

import (
	"io"
	"koding/db/mongodb"
	"koding/tools/logger"
	"koding/virt"
	"net"
	"strconv"
	"strings"
	"sync"
	"time"

	ber "github.com/hsoj/asn1-ber"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

var (
	log   = logger.New("ldapserver")
	mongo *mongodb.MongoDB

	vmCacheMu sync.Mutex
	vmCache   = make(map[bson.ObjectId]*virt.VM)

	userByUidCacheMu sync.Mutex
	userByUidCache   = make(map[int]*virt.User)

	userByNameCacheMu sync.Mutex
	userByNameCache   = make(map[string]*virt.User)
)

func Listen(mongodbUrl string) {
	mongo = mongodb.NewMongoDB(mongodbUrl)

	go func() {
		for {
			ClearCache()
			time.Sleep(10 * time.Second)
		}
	}()

	for {
		ln, err := net.Listen("tcp", ":389")
		if err != nil {
			log.LogError(err, 0)
			time.Sleep(time.Second)
			continue
		}
		for {
			conn, err := ln.Accept()
			if err != nil {
				log.LogError(err, 0)
				break
			}
			go handleConnection(conn)
		}
		ln.Close()
	}
}

func ClearCache() {
	vmCacheMu.Lock()
	vmCache = make(map[bson.ObjectId]*virt.VM, len(vmCache))
	vmCacheMu.Unlock()

	userByUidCacheMu.Lock()
	userByUidCache = make(map[int]*virt.User, len(userByUidCache))
	userByUidCacheMu.Unlock()

	userByNameCacheMu.Lock()
	userByNameCache = make(map[string]*virt.User, len(userByNameCache))
	userByNameCacheMu.Unlock()
}

func handleConnection(conn net.Conn) {
	defer log.RecoverAndLog()

	bound := false
	var vm *virt.VM

	for {
		packet, err := ber.ReadPacket(conn)
		if err != nil {
			if err == io.EOF {
				break
			}
			panic(err)
		}

		messageID := packet.Children[0].Value.(uint64)
		request := packet.Children[1]

		switch request.Tag {
		case ApplicationBindRequest:
			name := request.Children[1].Value.(string)
			password := request.Children[2].Data.String()
			bound, vm = authenticate(name, password)

			var resultCode uint64 = LDAPResultInvalidCredentials
			if bound {
				resultCode = LDAPResultSuccess
			}
			conn.Write(createSimpleResponse(messageID, ApplicationBindResponse, resultCode).Bytes())

		case ApplicationUnbindRequest:
			bound = false

		case ApplicationSearchRequest:
			if !bound {
				conn.Write(createSimpleResponse(messageID, ApplicationSearchResultDone, LDAPResultInsufficientAccessRights).Bytes())
				continue
			}

			if !lookupUser(request.Children[6], messageID, vm, conn) {
				// ber.PrintPacket(packet) // for debugging
			}

			conn.Write(createSimpleResponse(messageID, ApplicationSearchResultDone, LDAPResultSuccess).Bytes())

		default:
			panic("Unsupported LDAP command")
		}
	}
}

func authenticate(name, password string) (bool, *virt.VM) {
	if name == "vmhost" && password == "abc" {
		return true, nil
	}

	if strings.HasPrefix(name, "vm-") && bson.IsObjectIdHex(name[3:]) {
		id := bson.ObjectIdHex(name[3:])

		vmCacheMu.Lock()
		defer vmCacheMu.Unlock()

		vm, found := vmCache[id]
		if !found {
			err := mongo.Run("jVMs", func(c *mgo.Collection) error {
				return c.FindId(id).One(&vm)
			})
			if err != nil {
				return false, nil
			}
			vmCache[id] = vm
		}
		return password == vm.LdapPassword, vm
	}

	user, err := findUserByName(name)
	return err == nil && user.HasPassword(password), nil
}

func lookupUser(filter *ber.Packet, messageID uint64, vm *virt.VM, conn net.Conn) bool {
	switch findAttributeInFilter(filter, "objectClass") {
	case "posixGroup":
		if memberUid := findAttributeInFilter(filter, "memberUid"); memberUid != "" {
			if vm == nil {
				return true
			}

			user, err := findUserByName(memberUid)
			if err != nil {
				return true
			}
			permissions := vm.GetPermissions(user)
			if permissions == nil {
				return true
			}

			if permissions.Sudo {
				conn.Write(createGroupSearchResultEntry(messageID, "sudo", 27).Bytes())
			}

			conn.Write(createGroupSearchResultEntry(messageID, "www-data", 33).Bytes())

			return true
		}

		var user *virt.User
		var err error

		if gidStr := findAttributeInFilter(filter, "gidNumber"); gidStr != "" {
			gid, _ := strconv.Atoi(gidStr)
			user, err = findUserByUid(gid)
		}

		if name := findAttributeInFilter(filter, "cn"); name != "" {
			user, err = findUserByName(name)
		}

		if err != nil || (vm != nil && user != nil && vm.GetPermissions(user) == nil) {
			return true
		}

		if user != nil {
			conn.Write(createGroupSearchResultEntry(messageID, user.Name, user.Uid).Bytes())
			return true
		}

	default: // including "posixAccount"
		user, err := findUserInFilter(filter)
		if err == nil && user == nil {
			return false
		}
		if err != nil || (vm != nil && vm.GetPermissions(user) == nil) {
			return true
		}

		if user.Shell == "" {
			user.Shell = "/bin/bash"
		}

		conn.Write(createSearchResultEntry(messageID, map[string]string{
			"objectClass":   "posixAccount",
			"cn":            user.Name,
			"uid":           user.Name,
			"uidNumber":     strconv.Itoa(user.Uid),
			"gidNumber":     strconv.Itoa(user.Uid),
			"homeDirectory": "/home/" + user.Name,
			"loginShell":    user.Shell,
			"sshPublicKey":  strings.Join(user.SshKeyList(), "\n"),
		}).Bytes())
		return true

	}

	return false
}

func findUserInFilter(filter *ber.Packet) (*virt.User, error) {
	if name := findAttributeInFilter(filter, "uid"); name != "" {
		return findUserByName(name)
	}
	if uidStr := findAttributeInFilter(filter, "uidNumber"); uidStr != "" {
		uid, _ := strconv.Atoi(uidStr)
		return findUserByUid(uid)
	}
	return nil, nil
}

func findUser(query interface{}) (*virt.User, error) {
	var user virt.User
	err := mongo.Run("jUsers", func(c *mgo.Collection) error {
		return c.Find(query).One(&user)
	})
	if err != nil {
		return nil, err
	}
	if user.Uid < virt.UserIdOffset {
		panic("User with too low uid.")
	}
	return &user, nil
}

func findUserByUid(id int) (*virt.User, error) {
	userByUidCacheMu.Lock()
	defer userByUidCacheMu.Unlock()

	if user := userByUidCache[id]; user != nil {
		return user, nil
	}
	user, err := findUser(bson.M{"uid": id})
	userByUidCache[id] = user
	return user, err
}

func findUserByName(name string) (*virt.User, error) {
	userByNameCacheMu.Lock()
	defer userByNameCacheMu.Unlock()

	if user := userByNameCache[name]; user != nil {
		return user, nil
	}
	user, err := findUser(bson.M{"username": name})
	userByNameCache[name] = user
	return user, err
}

func findAttributeInFilter(filter *ber.Packet, name string) string {
	switch filter.Tag {
	case 0, 1: // and, or
		for _, child := range filter.Children {
			if result := findAttributeInFilter(child, name); result != "" {
				return result
			}
		}
	case 3: // equalityMatch
		if filter.Children[0].Value == name {
			return filter.Children[1].Value.(string)
		}
	}
	return ""
}

func createLDAPMessage(messageID uint64) *ber.Packet {
	packet := ber.Encode(ber.ClassUniversal, ber.TypeConstructed, ber.TagSequence, nil, "LDAPMessage")
	packet.AppendChild(ber.NewInteger(ber.ClassUniversal, ber.TypePrimative, ber.TagInteger, messageID, "MessageID"))
	return packet
}

func createLDAPResponse(tag uint8, resultCode uint64) *ber.Packet {
	packet := ber.Encode(ber.ClassApplication, ber.TypeConstructed, tag, nil, "LDAPResponse")
	packet.AppendChild(ber.NewInteger(ber.ClassUniversal, ber.TypePrimative, ber.TagInteger, resultCode, "resultCode"))
	packet.AppendChild(ber.NewString(ber.ClassUniversal, ber.TypePrimative, ber.TagOctetString, "", "matchedDN"))
	packet.AppendChild(ber.NewString(ber.ClassUniversal, ber.TypePrimative, ber.TagOctetString, "", "errorMessage"))
	return packet
}

func createSimpleResponse(messageID uint64, tag uint8, resultCode uint64) *ber.Packet {
	response := createLDAPMessage(messageID)
	response.AppendChild(createLDAPResponse(tag, resultCode))
	return response
}

func createSearchResultEntry(messageID uint64, attributes map[string]string) *ber.Packet {
	response := createLDAPMessage(messageID)
	entry := ber.Encode(ber.ClassApplication, ber.TypeConstructed, ApplicationSearchResultEntry, nil, "SearchResultEntry")
	entry.AppendChild(ber.NewString(ber.ClassUniversal, ber.TypePrimative, ber.TagOctetString, attributes["cn"], "objectName"))
	attributeSequence := ber.Encode(ber.ClassUniversal, ber.TypeConstructed, ber.TagSequence, nil, "attributes")
	for key, value := range attributes {
		attributeSequence.AppendChild(createAttribute(key, value))
	}
	entry.AppendChild(attributeSequence)
	response.AppendChild(entry)
	return response
}

func createGroupSearchResultEntry(messageID uint64, name string, gid int) *ber.Packet {
	return createSearchResultEntry(messageID, map[string]string{
		"objectClass":  "posixGroup",
		"cn":           name,
		"gidNumber":    strconv.Itoa(gid),
		"userPassword": "{crypt}x",
	})
}

func createAttribute(name, value string) *ber.Packet {
	attribute := ber.Encode(ber.ClassUniversal, ber.TypeConstructed, ber.TagSequence, nil, "attribute")
	attribute.AppendChild(ber.NewString(ber.ClassUniversal, ber.TypePrimative, ber.TagOctetString, name, "type"))
	values := ber.Encode(ber.ClassUniversal, ber.TypeConstructed, ber.TagSet, nil, "values")
	values.AppendChild(ber.NewString(ber.ClassUniversal, ber.TypePrimative, ber.TagOctetString, value, "value"))
	attribute.AppendChild(values)
	return attribute
}

const (
	ApplicationBindRequest           = 0
	ApplicationBindResponse          = 1
	ApplicationUnbindRequest         = 2
	ApplicationSearchRequest         = 3
	ApplicationSearchResultEntry     = 4
	ApplicationSearchResultDone      = 5
	ApplicationModifyRequest         = 6
	ApplicationModifyResponse        = 7
	ApplicationAddRequest            = 8
	ApplicationAddResponse           = 9
	ApplicationDelRequest            = 10
	ApplicationDelResponse           = 11
	ApplicationModifyDNRequest       = 12
	ApplicationModifyDNResponse      = 13
	ApplicationCompareRequest        = 14
	ApplicationCompareResponse       = 15
	ApplicationAbandonRequest        = 16
	ApplicationSearchResultReference = 19
	ApplicationExtendedRequest       = 23
	ApplicationExtendedResponse      = 24
)

const (
	LDAPResultSuccess                      = 0
	LDAPResultOperationsError              = 1
	LDAPResultProtocolError                = 2
	LDAPResultTimeLimitExceeded            = 3
	LDAPResultSizeLimitExceeded            = 4
	LDAPResultCompareFalse                 = 5
	LDAPResultCompareTrue                  = 6
	LDAPResultAuthMethodNotSupported       = 7
	LDAPResultStrongAuthRequired           = 8
	LDAPResultReferral                     = 10
	LDAPResultAdminLimitExceeded           = 11
	LDAPResultUnavailableCriticalExtension = 12
	LDAPResultConfidentialityRequired      = 13
	LDAPResultSaslBindInProgress           = 14
	LDAPResultNoSuchAttribute              = 16
	LDAPResultUndefinedAttributeType       = 17
	LDAPResultInappropriateMatching        = 18
	LDAPResultConstraintViolation          = 19
	LDAPResultAttributeOrValueExists       = 20
	LDAPResultInvalidAttributeSyntax       = 21
	LDAPResultNoSuchObject                 = 32
	LDAPResultAliasProblem                 = 33
	LDAPResultInvalidDNSyntax              = 34
	LDAPResultAliasDereferencingProblem    = 36
	LDAPResultInappropriateAuthentication  = 48
	LDAPResultInvalidCredentials           = 49
	LDAPResultInsufficientAccessRights     = 50
	LDAPResultBusy                         = 51
	LDAPResultUnavailable                  = 52
	LDAPResultUnwillingToPerform           = 53
	LDAPResultLoopDetect                   = 54
	LDAPResultNamingViolation              = 64
	LDAPResultObjectClassViolation         = 65
	LDAPResultNotAllowedOnNonLeaf          = 66
	LDAPResultNotAllowedOnRDN              = 67
	LDAPResultEntryAlreadyExists           = 68
	LDAPResultObjectClassModsProhibited    = 69
	LDAPResultAffectsMultipleDSAs          = 71
	LDAPResultOther                        = 80

	ErrorNetwork         = 200
	ErrorFilterCompile   = 201
	ErrorFilterDecompile = 202
	ErrorDebugging       = 203
)
