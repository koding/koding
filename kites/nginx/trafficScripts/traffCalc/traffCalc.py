#!/usr/bin/env python
__author__ = 'Aleksey Mykhailov'
__email__  = 'aleksey@kodingen.com'

import sys
import datetime
from pymongo import Connection
from pymongo.errors import ConnectionFailure
from pymongo.errors import OperationFailure
from  bson.objectid import ObjectId


debug = True

class TrafficStatistic(object):
    """ Calculating daily , monthly traffic for VirtualHost """

    def __init__(self,config):


        mongo_host = config.mongo_host
        mongo_user = config.mongo_user
        mongo_pass = config.mongo_pass
        database   = config.database


        try:
            self.log = open(config.traff_calc_log_file,'a+')
        except IOError,e:
            sys.stderr.write("Could not open log file %s: %s" %(config.log_file,e))
            sys.exit(1)


        try:
            connection = Connection(mongo_host, 27017)
            print("Connected to %s" % mongo_host)
        except ConnectionFailure,e:
            sys.stderr.write("Could not connect to mongoDB: %s" % e)
            sys.exit(1)

        self.db_handle = connection[database]
        assert self.db_handle.connection == connection
        self.db_handle.authenticate(mongo_user,mongo_pass)

        #creating indexes for "traffic" collection
        # create _id index manually
        self.db_handle.traffic.ensure_index('iscounted')
        #creating indexes for "pervhost_traff" collection
        self.db_handle.pervhost_traff.ensure_index('vhostname')

    def logger(self,message):
        now = datetime.datetime.now()
        now.ctime()
        self.log.write('[%s]: %s' % (now.ctime(),message))
        self.log.flush()

    def getbytes(self):

        for result in self.db_handle.traffic.find({"iscounted" : "false"}, {'vhostname':1,'out':1,'date':1,'_id':1}):
            yield result['vhostname'],result['out'],result['date'],result['_id']

    def change_record_status(self,id):

        try:
            self.db_handle.traffic.update({"_id":ObjectId(id)},{"$set": {"iscounted":"true"}})
        except OperationFailure,e:
            print("error in update: %s" % e )
            sys.exit(1)



    def update_monthly_traffic_usage(self,vhost,kbytes,current_month,traff_usage):

        old_month_stat = False

        for month in traff_usage['monthlyStat']:
            if month['month'] == current_month:
                old_month_stat = month['out']

        if not old_month_stat:
            self.logger('creating new month record for vhost %s with month %s\n' % (vhost,current_month))
            self.db_handle.pervhost_traff.update({'vhostname':vhost},
                                                 {'$push':{
                                                        'monthlyStat':{
                                                        'month':current_month,
                                                        'out':kbytes
                                                 }
                                                }})
            updated_month_usage = kbytes
        else:
            updated_month_usage = kbytes+old_month_stat


        self.logger("previous monthly %s Kb , updated %s Kb for %s\n" %
                    (old_month_stat,updated_month_usage,vhost))
        self.db_handle.pervhost_traff.update({'vhostname':vhost,
                                            "monthlyStat":{'$elemMatch':{"month":current_month}}
                                            },
                                            {'$set':{"monthlyStat.$.out":updated_month_usage}})

    def update_traff_statistic(self,vhost,kbytes,request_date):
        # "07/Dec/2011:05:33:12" get "07/Dec/2011"
        request_date = request_date.split(':')[0]
        current_month = request_date.split('/')[1]

        traff_usage = self.db_handle.pervhost_traff.find_one({"vhostname" : vhost})
        if not traff_usage:
            self.logger('creating doc for new vhost %s with %s Kb\n' % (vhost,kbytes))
            self.db_handle.pervhost_traff.update({'vhostname':vhost},
                                                {'$push':{
                                                    'dailyStat':{
                                                    'date':request_date,
                                                    'out':kbytes
                                                    },
                                                    'monthlyStat':{
                                                        'month':current_month,
                                                        'out':kbytes
                                                    }
                                                }},upsert=True)
        else:
            res = self.db_handle.pervhost_traff.find_one({"vhostname":vhost,"dailyStat":{"$elemMatch":{"date":request_date}}})

            if res:
                old_stat = 0
                for day in res['dailyStat']:
                    #if day['date'] == request_date:
                    #    old_stat = day['out'] #TODO: fix this
                    old_stat = day['out'] #TODO:check this
                updated_traff_usage = kbytes+old_stat

                self.logger("previous daily %s Kb , updated %s Kb for %s\n" %
                            (old_stat,updated_traff_usage,vhost))

                self.db_handle.pervhost_traff.update({'vhostname':vhost,
                                                     "dailyStat":{'$elemMatch':{"date":request_date}}
                                                    },
                                                    {'$set':{"dailyStat.$.out":updated_traff_usage}})

                self.update_monthly_traffic_usage(vhost,kbytes,current_month,traff_usage)

            else:
                #push stat for new date
                self.logger('creating new date record for vhost %s with date %s\n' % (vhost,request_date))
                self.db_handle.pervhost_traff.update({'vhostname':vhost},
                                                    {'$push':{
                                                        'dailyStat':{
                                                        'date':request_date,
                                                        'out':kbytes
                                                        }
                                                    }})
                self.update_monthly_traffic_usage(vhost,kbytes,current_month,traff_usage)

    # can't remove data from the capped collection
    #def purge_counted(self):
    #    try:
    #        self.db_handle.traffic.remove({'iscounted':'true'})
    #        self.logger("counted records was purged\n")
    #    except OperationFailure,e:
    #        print("error in purge counted records: %s" % e )
    #        sys.exit(1)

    def calculate(self):
        # vhostnames + traffic
        # 0 - result['vhostname'],
        # 1 - result['out'],
        # 2 - date['date'],
        # 3 - result['_id']

        vhosts_traff = [ result for result in self.getbytes() ]
        vhosts  = [ vhost[0] for vhost in vhosts_traff]
        uniq_vhosts = list(set(vhosts))

        for vhost in uniq_vhosts:
            traffic_sum = 0
            for record in vhosts_traff:
                if vhost in record[0]:
                    traffic_sum += int(record[1]) / 1024#Kb
                    # change iscounted there
                    self.change_record_status(record[3])
            if traffic_sum > 0:
                self.update_traff_statistic(vhost,traffic_sum,record[2])

def main():
    sys.exit(0)


if __name__ == '__main__':
    main()

