#!/usr/bin/python
import requests
import json
import sys
import argparse
from time import sleep
from pprint import  pprint



credentials = ('devrim', '>Npig4cVHyUG3RLc%URy')
apiUrl      = 'https://kodingen.beanstalkapp.com'




class Deploy:

    def __init__(self,credentials,
                 repoToDeploy,
                 branchToDeploy,
                 serverEnvironment,
                 serverToDeploy,
                 revision,
                 fromScratch=False
                ):

        self.repoToDeploy      = repoToDeploy
        self.branchToDeploy    = branchToDeploy
        self.serverEnvironment = serverEnvironment
        self.serverToDeploy    = serverToDeploy
        self.revision          = revision
        self.fromScratch       = fromScratch

        self.session  = requests.session(auth = credentials)
        self.session.config['danger_mode'] = True # raise exception immediately
        self.session.config['safe_mode']   = True
        try:
            self.session.get('%s/api/account.json' % apiUrl)
        except requests.exceptions.RequestException, error:
            sys.stderr.write(str(error))
            sys.exit(1)




    def findRepoID(self):
        repoID = None

        repos = self.session.get(apiUrl+'/api/repositories.json')
        repos = [{repo['repository'].get('name'):repo['repository'].get('id')} for repo in json.loads(repos.content)]
        for repo in repos:
            if repo.has_key(self.repoToDeploy):
                repoID = repo.get(self.repoToDeploy)
                return repoID

        if not repoID:
            sys.stderr.write("Can't find ID for repo %s" % self.repoToDeploy)
            sys.exit(1)


    def findServerEnv(self):
        envID = None

        self.repoID = self.findRepoID()
        envs = self.session.get("%s/api/%s/server_environments.json" % (apiUrl,self.repoID))
        for env in json.loads(envs.content):
            if env['server_environment'].get('name') == self.serverEnvironment:
                envID = env['server_environment'].get('id')
                return envID

        if not envID:
            pprint(envs.content)
            sys.stderr.write("Can't find environment ID for environment %s" % self.serverEnvironment)
            sys.exit(2)


    def findServer(self):
        serverID = None

        self.envID = self.findServerEnv()

        servers = self.session.get("%s/api/%s/release_servers.json?environment_id=%s" % (apiUrl,self.repoID,self.envID))
        for server in json.loads(servers.content):
            if server['release_server'].get('name') == self.serverToDeploy:
                serverID = server['release_server'].get('id')
                return serverID
        if not serverID:
            pprint(servers.content)
            sys.stderr.write("Can't find server ID for server %s" % self.serverToDeploy)
            sys.exit(3)


    def fetchDeploymentStatus(self,deploymentID=None):

        url = '%s/api/%s/releases/%s.json' % (apiUrl,self.repoID,deploymentID)
        sleep(2) # do not DoS beanstalk
        deploymentStatus = self.session.get(url)

        try:
            response = json.loads(deploymentStatus.content)
            if response.has_key('errors'):
                sys.stderr.write("Can't deploy: %s" % response.get('errors'))
                sys.exit(1)
            else:
                if response['release'].get('state') != 'success':
                    sys.stdout.write("Current deployment status: %s\n" % response['release'].get('state'))
                    self.fetchDeploymentStatus(deploymentID)
                else:
                    sys.stdout.write("Deployment finished with status: %s\n" % response['release'].get('state'))
        except ValueError,e:
            sys.stderr.write("Oops, something wasnt right. You can check deploymnent status at %s.\nScript error: %s\n" %
                            (url,e))
            sys.exit(4)




    def deployToServer(self):

        data = {
            "release":{
                "comment" :"test",
                "revision":self.revision
            }
        }

        self.serverID = self.findServer()
        if self.fromScratch:
            data['release']['deploy_from_scratch'] = 'true'

        startDeployment = self.session.post('%s/api/%s/releases.json?environment_id=%s' % (apiUrl,self.repoID,self.envID),
                                        json.dumps(data)
                                       )


        response = json.loads(startDeployment.content)
        if response.has_key('errors'):
            sys.stderr.write("Can't deploy: %s" % response.get('errors'))
        else:
            self.fetchDeploymentStatus(response['release'].get('id'))



if __name__=="__main__":



    parser = argparse.ArgumentParser(description="Deploy with beanstalk")
    parser.add_argument('-r','--repo', dest='repoToDeploy',help="Repository name which you want to deploy",required=True)
    parser.add_argument('-b','--branch', dest='branchToDeploy',help="Branch name which you want to deploy",required=True)
    parser.add_argument('-e','--env', dest='serverEnvironment',choices=['production','staging','dev'],required=True)
    parser.add_argument('-s','--server', dest='serverToDeploy',required=True)
    parser.add_argument('-g','--git-revision', dest='revision',help="Revision ID",required=True)
    parser.add_argument('-i','--initial', dest='fromScratch',help="Is it initial deployment?",action='store_true')

    args = parser.parse_args()

    deploy = Deploy(credentials,
                    args.repoToDeploy,
                    args.branchToDeploy,
                    args.serverEnvironment,
                    args.serverToDeploy,
                    args.revision,
                    args.fromScratch)

    deploy.deployToServer()

