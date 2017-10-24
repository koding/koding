#!/bin/bash

function k8s_connectivity_check () {
  # args: $1: POD NAME, $2: NAMESPACE, $3: container name
  kubectl exec -n $2 $1 -c $3 -- bash -c "./run is_ready" || exit 1
}

function k8s_health_check () {
  # args: $1: POD NAME, $2: NAMESPACE, $3: health check interval (recommended 5 seconds), $4: timeout duration
  declare interval=$3
  declare timeout=$4
  declare duration=0

  sleep $interval

  declare response_code=$(kubectl exec -n $2 $1 -c $5 -- echo 'i am alive' || exit 1)

  echo -n $5 : 'health-check : '

  until [[ $response_code != *"error"* ]]; do
    if [ $duration -eq $timeout ]; then
      echo ' timed out!'
      exit 255
    fi

    echo -n '.'

    sleep $interval
    duration=$((duration + interval))

    response_code=$(kubectl exec -n $2 $1 -c $5 -- echo 'i am alive' || exit 1)
  done

  echo ' succeeded!'
}

function check_pod_state () {
  remaining_time=600

  until eval "check_pod_response $1 $2 $3"; do
    sleep 5
    let remaining_time--
    if [ $remaining_time == 0 ]; then
      echo "time out!"
      exit 1
    fi
    echo -n '.'
  done

  echo "${1} is ready and running..."
}

function check_pod_response () {
  declare response_code=$(kubectl get pods --namespace koding $1 -o jsonpath="{.status.phase}" || exit 1)

  if [[ $response_code == *"${2}"* ]]; then
    return 1
  fi

  if [[ "${3}" == "Succeeded" && $response_code != *"${3}"* ]]; then
    echo "pod: ${1} is in the ${response_code} state, must've been in Succeded state. An error occurred, exiting."
    exit 1
  fi

  return 0
}

function create_rmq_test_user () {
  # guest user can only connect via localhost, a test user equivalent to guest will be created
  # to check connectivity via POD IP. more info on guest user update:
  # https://www.rabbitmq.com/blog/2014/04/02/breaking-things-with-rabbitmq-3-3/
  k8s_health_check $RABBITMQ_POD_NAME koding 5 120 rabbitmq
  sleep 10
  kubectl exec -n koding $RABBITMQ_POD_NAME -c rabbitmq -- bash -c "rabbitmqctl add_user test test"
  kubectl exec -n koding $RABBITMQ_POD_NAME -c rabbitmq -- bash -c "rabbitmqctl set_user_tags test administrator"
  kubectl exec -n koding $RABBITMQ_POD_NAME -c rabbitmq -- bash -c "rabbitmqctl set_permissions -p / test '.*' '.*' '.*'"
}

function create_k8s_resource () {
  kubectl apply -f $1 && sleep 3 || kubectl create -f $1 && sleep 3 || exit 1
}

function delete_k8s_resource () {
  kubectl delete -f $1
}

if [ "$(type -t $1)" ]; then
  "$@"
else
  echo "Error: Command not found: $1"
  echo "Usage: scripts/k8s-utilities COMMAND args"
  echo ""
  echo "Commands:  "
  echo "  k8s_connectivity_check : executes ./run is_ready from any pod that is specified"
  echo "  k8s_health_check  : stop the currently running Kubernetes cluster"
  echo "  check_pod_state  : wait until the pod is in the desired state (the state given in args)"
  echo "  create_k8s_resource  : create a k8s resource by specifying the resource file"
  echo "  delete_k8s_resource  : delete a k8s resource by specifying the resource file"
  echo "  create_rmq_test_user  : create a test user for rabbitmq connectivity check"
  echo ""

  exit 1
fi
