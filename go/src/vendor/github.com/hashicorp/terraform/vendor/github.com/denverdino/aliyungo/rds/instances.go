package rds

import (
	"github.com/denverdino/aliyungo/common"
	"time"
)

type DBInstanceIPArray struct {
	SecurityIps                string
	DBInstanceIPArrayName      string
	DBInstanceIPArrayAttribute string
}

// ref: https://help.aliyun.com/document_detail/26242.html
type ModifySecurityIpsArgs struct {
	DBInstanceId string
	DBInstanceIPArray
}

func (client *Client) ModifySecurityIps(args *ModifySecurityIpsArgs) (resp common.Response, err error) {
	response := common.Response{}
	err = client.Invoke("ModifySecurityIps", args, &response)
	return response, err
}

type DescribeDBInstanceIPsArgs struct {
	DBInstanceId string
}

type DBInstanceIPList struct {
	DBInstanceIPArrayName      string
	DBInstanceIPArrayAttribute string
	SecurityIPList             string
}

type DescribeDBInstanceIPsResponse struct {
	common.Response
	Items struct {
		DBInstanceIPArray []DBInstanceIPList
	}
}

// DescribeDBInstanceIPArrayList describe security ips
//
// You can read doc at https://help.aliyun.com/document_detail/26241.html?spm=5176.doc26242.6.715.d9pxvr
func (client *Client) DescribeDBInstanceIPs(args *DescribeDBInstanceIPsArgs) (resp *DescribeDBInstanceIPsResponse, err error) {
	response := DescribeDBInstanceIPsResponse{}
	err = client.Invoke("DescribeDBInstanceIPArrayList", args, &response)

	if err != nil {
		return nil, err
	}
	return &response, nil
}

// InstanceStatus represents instance status
type InstanceStatus string

// Constants of InstanceStatus
const (
	Creating  = InstanceStatus("Creating") // For backward compatability
	Running   = InstanceStatus("Running")
	Deleting  = InstanceStatus("Deleting")
	Rebooting = InstanceStatus("Rebooting")

	Restoring                 = InstanceStatus("Restoring")
	Importing                 = InstanceStatus("Importing")
	DBInstanceNetTypeChanging = InstanceStatus("DBInstanceNetTypeChanging")
)

type DBPayType string

const (
	Prepaid  = DBPayType("Prepaid")
	Postpaid = DBPayType("Postpaid")
)

type CommodityCode string

const (
	Rds   = CommodityCode("rds")
	Bards = CommodityCode("bards")
	Rords = CommodityCode("rords")
)

type Engine string

const (
	MySQL     = Engine("MySQL")
	SQLServer = Engine("SQLServer")
	PPAS      = Engine("PPAS")
	PG        = Engine("PG")
)

type ConnectionMode string

const (
	Performance = ConnectionMode("Performance")
	Safty       = ConnectionMode("Safty")
)

// default resource value for create order
const DefaultResource = "buy"

type CreateOrderArgs struct {
	CommodityCode       CommodityCode
	RegionId            common.Region
	ZoneId              string
	Engine              Engine
	EngineVersion       string
	PayType             DBPayType
	DBInstanceClass     string
	DBInstanceStorage   int
	DBInstanceNetType   common.NetType
	InstanceNetworkType common.NetworkType
	VPCId               string
	VSwitchId           string
	UsedTime            int
	TimeType            common.TimeType
	Quantity            int
	InstanceUsedType    string
	Resource            string
	AutoPay             string
	AutoRenew           string
	BackupId            string
	RestoreTime         string
	SecurityIPList      string
	BusinessInfo        string
}

type CreateOrderResponse struct {
	common.Response
	DBInstanceId string
	OrderId      int
}

// CreateOrder create db instance order
// you can read doc at http://docs.alibaba-inc.com/pages/viewpage.action?pageId=259349053
func (client *Client) CreateOrder(args *CreateOrderArgs) (resp CreateOrderResponse, err error) {
	response := CreateOrderResponse{}
	err = client.Invoke("CreateOrder", args, &response)
	return response, err
}

type DescribeDBInstancesArgs struct {
	DBInstanceId string
}

type DescribeDBInstanceAttributeResponse struct {
	common.Response
	Items struct {
		DBInstanceAttribute []DBInstanceAttribute
	}
}

type DBInstanceAttribute struct {
	DBInstanceId                string
	PayType                     DBPayType
	DBInstanceType              string
	InstanceNetworkType         string
	ConnectionMode              string
	RegionId                    string
	ZoneId                      string
	ConnectionString            string
	Port                        string
	Engine                      Engine
	EngineVersion               string
	DBInstanceClass             string
	DBInstanceMemory            int64
	DBInstanceStorage           int
	DBInstanceNetType           string
	DBInstanceStatus            InstanceStatus
	DBInstanceDescription       string
	LockMode                    string
	LockReason                  string
	DBMaxQuantity               int
	AccountMaxQuantity          int
	CreationTime                string
	ExpireTime                  string
	MaintainTime                string
	AvailabilityValue           string
	MaxIOPS                     int
	MaxConnections              int
	MasterInstanceId            string
	IncrementSourceDBInstanceId string
	GuardDBInstanceId           string
	TempDBInstanceId            string
	ReadOnlyDBInstanceIds       ReadOnlyDBInstanceIds
	SecurityIPList              string
}

type ReadOnlyDBInstanceIds struct {
	ReadOnlyDBInstanceId []string
}

// DescribeDBInstanceAttribute describes db instance
//
// You can read doc at https://help.aliyun.com/document_detail/26231.html?spm=5176.doc26228.6.702.uhzm31
func (client *Client) DescribeDBInstanceAttribute(args *DescribeDBInstancesArgs) (resp *DescribeDBInstanceAttributeResponse, err error) {

	response := DescribeDBInstanceAttributeResponse{}

	err = client.Invoke("DescribeDBInstanceAttribute", args, &response)

	if err == nil {
		return &response, nil
	}

	return nil, err
}

type DescribeDatabasesArgs struct {
	DBInstanceId string
	DBName       string
	DBStatus     InstanceStatus
}

type DescribeDatabasesResponse struct {
	common.Response
	Databases struct {
		Database []Database
	}
}

type Database struct {
	DBName           string
	DBInstanceId     string
	Engine           string
	DBStatus         InstanceStatus
	CharacterSetName InstanceStatus
	DBDescription    InstanceStatus
	Account          InstanceStatus
	AccountPrivilege InstanceStatus
	Accounts         struct {
		AccountPrivilegeInfo []AccountPrivilegeInfo
	}
}

type AccountPrivilegeInfo struct {
	Account          string
	AccountPrivilege string
}

// DescribeDatabases describes db database
//
// You can read doc at https://help.aliyun.com/document_detail/26260.html?spm=5176.doc26258.6.732.gCx1a3
func (client *Client) DescribeDatabases(args *DescribeDatabasesArgs) (resp *DescribeDatabasesResponse, err error) {

	response := DescribeDatabasesResponse{}

	err = client.Invoke("DescribeDatabases", args, &response)

	if err == nil {
		return &response, nil
	}

	return nil, err
}

type DescribeAccountsArgs struct {
	DBInstanceId string
	AccountName  string
}

type DescribeAccountsResponse struct {
	common.Response
	Accounts struct {
		DBInstanceAccount []DBInstanceAccount
	}
}

type DBInstanceAccount struct {
	DBInstanceId       string
	AccountName        string
	AccountStatus      AccountStatus
	AccountDescription string
	DatabasePrivileges struct {
		DatabasePrivilege []DatabasePrivilege
	}
}

type AccountStatus string

const (
	Unavailable = AccountStatus("Unavailable")
	Available   = AccountStatus("Available")
)

type DatabasePrivilege struct {
	DBName           string
	AccountPrivilege AccountPrivilege
}

// DescribeAccounts describes db accounts
//
// You can read doc at https://help.aliyun.com/document_detail/26265.html?spm=5176.doc26266.6.739.UjtjaI
func (client *Client) DescribeAccounts(args *DescribeAccountsArgs) (resp *DescribeAccountsResponse, err error) {

	response := DescribeAccountsResponse{}

	err = client.Invoke("DescribeAccounts", args, &response)

	if err == nil {
		return &response, nil
	}

	return nil, err
}

// Default timeout value for WaitForInstance method
const InstanceDefaultTimeout = 120
const DefaultWaitForInterval = 10

// WaitForInstance waits for instance to given status
func (client *Client) WaitForInstance(instanceId string, status InstanceStatus, timeout int) error {
	if timeout <= 0 {
		timeout = InstanceDefaultTimeout
	}
	for {
		args := DescribeDBInstancesArgs{
			DBInstanceId: instanceId,
		}

		resp, err := client.DescribeDBInstanceAttribute(&args)
		if err != nil {
			return err
		}

		if timeout <= 0 {
			return common.GetClientErrorFromString("Timeout")
		}

		timeout = timeout - DefaultWaitForInterval
		time.Sleep(DefaultWaitForInterval * time.Second)

		if len(resp.Items.DBInstanceAttribute) < 1 {
			continue
		}
		instance := resp.Items.DBInstanceAttribute[0]
		if instance.DBInstanceStatus == status {
			break
		}

	}
	return nil
}

// WaitForInstance waits for instance to given status
func (client *Client) WaitForInstanceAsyn(instanceId string, status InstanceStatus, timeout int) error {
	if timeout <= 0 {
		timeout = InstanceDefaultTimeout
	}
	for {
		args := DescribeDBInstancesArgs{
			DBInstanceId: instanceId,
		}

		resp, err := client.DescribeDBInstanceAttribute(&args)
		if err != nil {
			e, _ := err.(*common.Error)
			if e.Code != "InvalidInstanceId.NotFound" && e.Code != "Forbidden.InstanceNotFound" {
				return err
			}
		}

		if timeout <= 0 {
			return common.GetClientErrorFromString("Timeout")
		}

		timeout = timeout - DefaultWaitForInterval
		time.Sleep(DefaultWaitForInterval * time.Second)
		if resp != nil {

			if len(resp.Items.DBInstanceAttribute) < 1 {
				continue
			}
			instance := resp.Items.DBInstanceAttribute[0]
			if instance.DBInstanceStatus == status {
				break
			}
		}
	}
	return nil
}

func (client *Client) WaitForAllDatabase(instanceId string, databaseNames []string, status InstanceStatus, timeout int) error {
	if timeout <= 0 {
		timeout = InstanceDefaultTimeout
	}
	for {
		args := DescribeDatabasesArgs{
			DBInstanceId: instanceId,
		}

		resp, err := client.DescribeDatabases(&args)
		if err != nil {
			return err
		}

		if timeout <= 0 {
			return common.GetClientErrorFromString("Timeout")
		}

		timeout = timeout - DefaultWaitForInterval
		time.Sleep(DefaultWaitForInterval * time.Second)

		ready := 0

		for _, nm := range databaseNames {
			for _, db := range resp.Databases.Database {
				if db.DBName == nm {
					if db.DBStatus == status {
						ready++
						break
					}
				}
			}
		}

		if ready == len(databaseNames) {
			break
		}

	}
	return nil
}

func (client *Client) WaitForAccount(instanceId string, accountName string, status AccountStatus, timeout int) error {
	if timeout <= 0 {
		timeout = InstanceDefaultTimeout
	}
	for {
		args := DescribeAccountsArgs{
			DBInstanceId: instanceId,
			AccountName:  accountName,
		}

		resp, err := client.DescribeAccounts(&args)
		if err != nil {
			return err
		}

		accs := resp.Accounts.DBInstanceAccount

		if timeout <= 0 {
			return common.GetClientErrorFromString("Timeout")
		}

		timeout = timeout - DefaultWaitForInterval
		time.Sleep(DefaultWaitForInterval * time.Second)

		if len(accs) < 1 {
			continue
		}

		acc := accs[0]

		if acc.AccountStatus == status {
			break
		}

	}
	return nil
}

func (client *Client) WaitForPublicConnection(instanceId string, timeout int) error {
	if timeout <= 0 {
		timeout = InstanceDefaultTimeout
	}
	for {
		args := DescribeDBInstanceNetInfoArgs{
			DBInstanceId: instanceId,
		}

		resp, err := client.DescribeDBInstanceNetInfo(&args)
		if err != nil {
			return err
		}

		if timeout <= 0 {
			return common.GetClientErrorFromString("Timeout")
		}

		timeout = timeout - DefaultWaitForInterval
		time.Sleep(DefaultWaitForInterval * time.Second)

		ready := false
		for _, info := range resp.DBInstanceNetInfos.DBInstanceNetInfo {
			if info.IPType == Public {
				ready = true
			}
		}

		if ready {
			break
		}

	}
	return nil
}

func (client *Client) WaitForAccountPrivilege(instanceId, accountName, dbName string, privilege AccountPrivilege, timeout int) error {
	if timeout <= 0 {
		timeout = InstanceDefaultTimeout
	}
	for {
		args := DescribeAccountsArgs{
			DBInstanceId: instanceId,
			AccountName:  accountName,
		}

		resp, err := client.DescribeAccounts(&args)
		if err != nil {
			return err
		}

		accs := resp.Accounts.DBInstanceAccount

		if timeout <= 0 {
			return common.GetClientErrorFromString("Timeout")
		}

		timeout = timeout - DefaultWaitForInterval
		time.Sleep(DefaultWaitForInterval * time.Second)

		if len(accs) < 1 {
			continue
		}

		acc := accs[0]

		ready := false
		for _, dp := range acc.DatabasePrivileges.DatabasePrivilege {
			if dp.DBName == dbName && dp.AccountPrivilege == privilege {
				ready = true
			}
		}

		if ready {
			break
		}

	}
	return nil
}

type DeleteDBInstanceArgs struct {
	DBInstanceId string
}

type DeleteDBInstanceResponse struct {
	common.Response
}

// DeleteInstance deletes db instance
//
// You can read doc at https://help.aliyun.com/document_detail/26229.html?spm=5176.doc26315.6.700.7SmyAT
func (client *Client) DeleteInstance(instanceId string) error {
	args := DeleteDBInstanceArgs{DBInstanceId: instanceId}
	response := DeleteDBInstanceResponse{}
	err := client.Invoke("DeleteDBInstance", &args, &response)
	return err
}

type DeleteDatabaseArgs struct {
	DBInstanceId string
	DBName       string
}

type DeleteDatabaseResponse struct {
	common.Response
}

// DeleteInstance deletes database
//
// You can read doc at https://help.aliyun.com/document_detail/26259.html?spm=5176.doc26260.6.731.Abjwne
func (client *Client) DeleteDatabase(instanceId, dbName string) error {
	args := DeleteDatabaseArgs{
		DBInstanceId: instanceId,
		DBName:       dbName,
	}
	response := DeleteDatabaseResponse{}
	err := client.Invoke("DeleteDatabase", &args, &response)
	return err
}

type DescribeRegionsArgs struct {
}

type DescribeRegionsResponse struct {
	Regions struct {
		RDSRegion []RDSRegion
	}
}

type RDSRegion struct {
	RegionId string
	ZoneId   string
}

// DescribeRegions describe rds regions
//
// You can read doc at https://help.aliyun.com/document_detail/26243.html?spm=5176.doc26244.6.715.OSNUa8
func (client *Client) DescribeRegions() (resp *DescribeRegionsResponse, err error) {
	args := DescribeRegionsArgs{}
	response := DescribeRegionsResponse{}
	err = client.Invoke("DescribeRegions", &args, &response)

	if err != nil {
		return nil, err
	}
	return &response, nil
}

type CreateDatabaseResponse struct {
	common.Response
}

type CreateDatabaseArgs struct {
	DBInstanceId     string
	DBName           string
	CharacterSetName string
	DBDescription    string
}

// CreateDatabase create rds database
//
// You can read doc at https://help.aliyun.com/document_detail/26243.html?spm=5176.doc26244.6.715.OSNUa8
func (client *Client) CreateDatabase(args *CreateDatabaseArgs) (resp *CreateDatabaseResponse, err error) {
	response := CreateDatabaseResponse{}
	err = client.Invoke("CreateDatabase", args, &response)

	if err != nil {
		return nil, err
	}
	return &response, nil
}

type CreateAccountResponse struct {
	common.Response
}

type AccountType struct {
	Normal string
	Super  string
}

type CreateAccountArgs struct {
	DBInstanceId       string
	AccountName        string
	AccountPassword    string
	AccountType        AccountType
	AccountDescription string
}

// CreateAccount create rds account
//
// You can read doc at https://help.aliyun.com/document_detail/26263.html?spm=5176.doc26240.6.736.ZDihok
func (client *Client) CreateAccount(args *CreateAccountArgs) (resp *CreateAccountResponse, err error) {
	response := CreateAccountResponse{}
	err = client.Invoke("CreateAccount", args, &response)

	if err != nil {
		return nil, err
	}
	return &response, nil
}

type DeleteAccountResponse struct {
	common.Response
}

type DeleteAccountArgs struct {
	DBInstanceId string
	AccountName  string
}

// DeleteAccount delete account
//
// You can read doc at https://help.aliyun.com/document_detail/26264.html?spm=5176.doc26269.6.737.CvlZp6
func (client *Client) DeleteAccount(instanceId, accountName string) (resp *DeleteAccountResponse, err error) {
	args := DeleteAccountArgs{
		DBInstanceId: instanceId,
		AccountName:  accountName,
	}

	response := DeleteAccountResponse{}
	err = client.Invoke("DeleteAccount", &args, &response)

	if err != nil {
		return nil, err
	}
	return &response, nil
}

type GrantAccountPrivilegeResponse struct {
	common.Response
}

type GrantAccountPrivilegeArgs struct {
	DBInstanceId     string
	AccountName      string
	DBName           string
	AccountPrivilege AccountPrivilege
}

type AccountPrivilege string

const (
	ReadOnly  = AccountPrivilege("ReadOnly")
	ReadWrite = AccountPrivilege("ReadWrite")
)

// GrantAccountPrivilege grant database privilege to account
//
// You can read doc at https://help.aliyun.com/document_detail/26266.html?spm=5176.doc26264.6.739.o2y01n
func (client *Client) GrantAccountPrivilege(args *GrantAccountPrivilegeArgs) (resp *GrantAccountPrivilegeResponse, err error) {
	response := GrantAccountPrivilegeResponse{}
	err = client.Invoke("GrantAccountPrivilege", args, &response)

	if err != nil {
		return nil, err
	}
	return &response, nil
}

type AllocateInstancePublicConnectionResponse struct {
	common.Response
}

type AllocateInstancePublicConnectionArgs struct {
	DBInstanceId           string
	ConnectionStringPrefix string
	Port                   string
}

// AllocateInstancePublicConnection allocate public connection
//
// You can read doc at https://help.aliyun.com/document_detail/26234.html?spm=5176.doc26265.6.708.PdsJnL
func (client *Client) AllocateInstancePublicConnection(args *AllocateInstancePublicConnectionArgs) (resp *AllocateInstancePublicConnectionResponse, err error) {
	response := AllocateInstancePublicConnectionResponse{}
	err = client.Invoke("AllocateInstancePublicConnection", args, &response)

	if err != nil {
		return nil, err
	}
	return &response, nil
}

type DescribeDBInstanceNetInfoArgs struct {
	DBInstanceId string
}

type DescribeDBInstanceNetInfoResponse struct {
	common.Response
	InstanceNetworkType string
	DBInstanceNetInfos  struct {
		DBInstanceNetInfo []DBInstanceNetInfo
	}
}

type DBInstanceNetInfo struct {
	ConnectionString string
	IPAddress        string
	Port             string
	VPCId            string
	VSwitchId        string
	IPType           IPType
}

type IPType string

const (
	Inner   = IPType("Inner")
	Private = IPType("Private")
	Public  = IPType("Public")
)

// DescribeDBInstanceNetInfo describe rds net info
//
// You can read doc at https://help.aliyun.com/document_detail/26237.html?spm=5176.doc26234.6.711.vHOktx
func (client *Client) DescribeDBInstanceNetInfo(args *DescribeDBInstanceNetInfoArgs) (resp *DescribeDBInstanceNetInfoResponse, err error) {
	response := DescribeDBInstanceNetInfoResponse{}
	err = client.Invoke("DescribeDBInstanceNetInfo", args, &response)

	if err != nil {
		return nil, err
	}
	return &response, nil
}

type BackupPolicy struct {
	PreferredBackupTime      string // HH:mmZ - HH:mm Z
	PreferredBackupPeriod    string // Monday - Sunday
	BackupRetentionPeriod    int    // 7 - 730
	BackupLog                string // enum Enable | Disabled
	LogBackupRetentionPeriod string
}

type ModifyBackupPolicyArgs struct {
	DBInstanceId string
	BackupPolicy
}

type ModifyBackupPolicyResponse struct {
	common.Response
}

// ModifyBackupPolicy modify backup policy
//
// You can read doc at https://help.aliyun.com/document_detail/26276.html?spm=5176.doc26250.6.751.KOew21
func (client *Client) ModifyBackupPolicy(args *ModifyBackupPolicyArgs) (resp *ModifyBackupPolicyResponse, err error) {
	response := ModifyBackupPolicyResponse{}
	err = client.Invoke("ModifyBackupPolicy", args, &response)

	if err != nil {
		return nil, err
	}
	return &response, nil
}

type DescribeBackupPolicyArgs struct {
	DBInstanceId string
}

type DescribeBackupPolicyResponse struct {
	common.Response
	BackupPolicy
}

// DescribeBackupPolicy describe backup policy
//
// You can read doc at https://help.aliyun.com/document_detail/26275.html?spm=5176.doc26276.6.750.CUqjDn
func (client *Client) DescribeBackupPolicy(args *DescribeBackupPolicyArgs) (resp *DescribeBackupPolicyResponse, err error) {
	response := DescribeBackupPolicyResponse{}
	err = client.Invoke("DescribeBackupPolicy", args, &response)

	if err != nil {
		return nil, err
	}
	return &response, nil
}

type ModifyDBInstanceSpecArgs struct {
	DBInstanceId      string
	PayType           DBPayType
	DBInstanceClass   string
	DBInstanceStorage string
}

type ModifyDBInstanceSpecResponse struct {
	common.Response
}

// ModifyDBInstanceSpec modify db instance spec
//
// You can read doc at https://help.aliyun.com/document_detail/26233.html?spm=5176.doc26258.6.707.2QOLrM
func (client *Client) ModifyDBInstanceSpec(args *ModifyDBInstanceSpecArgs) (resp *ModifyDBInstanceSpecResponse, err error) {
	response := ModifyDBInstanceSpecResponse{}
	err = client.Invoke("ModifyDBInstanceSpec", args, &response)

	if err != nil {
		return nil, err
	}
	return &response, nil
}

var WEEK_ENUM = []string{"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"}

var BACKUP_TIME = []string{
	"00:00Z-01:00Z", "01:00Z-02:00Z", "02:00Z-03:00Z", "03:00Z-04:00Z", "04:00Z-05:00Z",
	"05:00Z-06:00Z", "06:00Z-07:00Z", "07:00Z-08:00Z", "08:00Z-09:00Z", "09:00Z-10:00Z",
	"10:00Z-11:00Z", "11:00Z-12:00Z", "12:00Z-13:00Z", "13:00Z-14:00Z", "14:00Z-15:00Z",
	"15:00Z-16:00Z", "16:00Z-17:00Z", "17:00Z-18:00Z", "18:00Z-19:00Z", "19:00Z-20:00Z",
	"20:00Z-21:00Z", "21:00Z-22:00Z", "22:00Z-23:00Z", "23:00Z-24:00Z",
}

var CHARACTER_SET_NAME = []string{
	"utf8", "gbk", "latin1", "utf8mb4",
	"Chinese_PRC_CI_AS", "Chinese_PRC_CS_AS", "SQL_Latin1_General_CP1_CI_AS", "SQL_Latin1_General_CP1_CS_AS", "Chinese_PRC_BIN",
}
