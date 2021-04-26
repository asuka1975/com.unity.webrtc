#!/bin/bash -eu

#
# BOKKEN_DEVICE_IP: 
# TEMPLATE_FILE: 
# TEST_TARGET:
# TEST_PLATFORM:
# SCRIPTING_BACKEND:
# EXTRA_EDITOR_ARG:
# PACKAGE_DIR:
# TEST_PROJECT_DIR:
# TEST_RESULT_DIR:
# EDITOR_VERSION:
#
# 
# brew install gettext
#

export IDENTITY=~/.ssh/id_rsa_macmini

# install envsubst command
brew install gettext

# render template
envsubst ' \
  $SCRIPTING_BACKEND \
  $EXTRA_EDITOR_ARG \
  $PLAYER_LOAD_PATH \
  $TEST_PROJECT_DIR \
  $TEST_TARGET \
  $TEST_PLATFORM \
  $EDITOR_VERSION' \
  < ${TEMPLATE_FILE} \
  > ~/remote.sh
chmod +x ~/remote.sh

# copy shell script to remote machine
scp -i ${IDENTITY} -r ~/remote.sh bokken@${BOKKEN_DEVICE_IP}:~/remote.sh

# copy build player
scp -i ${IDENTITY} -r build bokken@${BOKKEN_DEVICE_IP}:~/

# run remote.sh on the remote machine
ssh -i ${IDENTITY} bokken@${BOKKEN_DEVICE_IP} ~/remote.sh
result=$?

# copy artifacts from the remote machine
mkdir -p ${TEST_RESULT_DIR}
scp -i ${IDENTITY} -r bokken@${BOKKEN_DEVICE_IP}:~/test-results ${TEST_RESULT_DIR}

# return ssh commend results 
if [ $result -ne 0 ]; then
  exit $result
fi