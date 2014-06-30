#/!bin/bash

# Remove all stopped containers.
docker rm -f $(docker ps -a -q)

# Remove all untagged images
# docker rm -fi $(docker images | grep "^<none>" | awk "{print $3}")


docker stop mongo          
docker stop postgres       
docker stop rabbitmq       
docker stop redis          
docker stop kontrol        
docker stop proxy          
docker stop kloud          
docker stop rerouting      
docker stop webserver      
docker stop sourceMapServer
docker stop authWorker     
docker stop social         
docker stop guestCleaner   
docker stop cronJobs       
docker stop broker         
docker stop emailSender   

docker stop dailymailnotifier
docker stop notification
docker stop popularpost
docker stop populartopic
docker stop realtime
docker stop sitemapfeeder
docker stop topicfeed
docker stop trollmode

docker rm -f mongo          
docker rm -f postgres       
docker rm -f rabbitmq       
docker rm -f redis          
docker rm -f kontrol        
docker rm -f proxy          
docker rm -f kloud          
docker rm -f rerouting      
docker rm -f webserver      
docker rm -f sourceMapServer
docker rm -f authWorker     
docker rm -f social         
docker rm -f guestCleaner   
docker rm -f cronJobs       
docker rm -f broker         
docker rm -f emailSender     

docker rm -f dailymailnotifier
docker rm -f notification
docker rm -f popularpost
docker rm -f populartopic
docker rm -f realtime
docker rm -f sitemapfeeder
docker rm -f topicfeed
docker rm -f trollmode

