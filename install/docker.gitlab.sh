docker run --name='gitlab' -d -v /gitlab:/home/git/data -p 10022:22 -p 10080:80 --net=host -e "GITLAB_PORT=10080" -e "GITLAB_SSH_PORT=10022" sameersbn/gitlab

