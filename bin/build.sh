#!/bin/bash

# The source_dir is the last segment from repository URL
source_dir=$(echo $SOURCE_URI | grep -o -e "[^/]*$" | sed -e "s/\.git$//")

result=1

if [ -z "${IMAGE_NAME}" ]; then
  echo "[ERROR] The IMAGE_NAME environment variable must be set"
  exit $result
fi

# Clone the STI image repository
echo "git clone $SOURCE_URI"
git clone $SOURCE_URI

if ! [ $? -eq 0 ]; then
  echo "[ERROR] Unable to clone the STI image repository."
  exit $result
fi


pushd $source_dir >/dev/null
  
   # Checkout desired ref
  if ! [ -z "$SOURCE_REF" ]; then
    git checkout $SOURCE_REF
  fi

    #for context we need to change dir
  if ! [ -z "$CONTEXT_DIR" ]; then
    echo "Changing context folder"
    CONTEXT=$(echo $CONTEXT_DIR | sed -r 's/\///g')
      cd $CONTEXT
  fi

  docker build -t ${IMAGE_NAME}-candidate .
  result=$?
  if ! [ $result -eq 0 ]; then
    echo "[ERROR] Unable to build ${IMAGE_NAME}-candidate image (${result})"
  fi

  # Verify the 'test/run' is present
  if ! [ -x "./test/run" ]; then
    echo "[ERROR] Unable to locate the 'test/run' command for the image"
    exit 1
  fi

  # Execute tests
  ./test/run
  result=$?
  if [ $result -eq 0 ]; then
    echo "[SUCCESS] ${IMAGE_NAME} image tests executed successfully"
  else
    echo "[FAILURE] ${IMAGE_NAME} image tests failed ($result)"
    exit $result
  fi
popd >/dev/null

# After successfull build, retag the image to 'qa-ready'
# TODO: Define image promotion process
#
image_id=$(docker inspect --format="{{ .Id }}" ${IMAGE_NAME}-candidate:latest)
docker tag ${image_id} ${IMAGE_NAME}:qa-ready
docker tag ${image_id} ${IMAGE_NAME}:git-$SOURCE_REF
