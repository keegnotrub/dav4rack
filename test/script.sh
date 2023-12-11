#!/bin/sh 

# Run buitin spec tests
bundle exec rspec

if [ $? -ne 0 ] ; then
  echo "*** Specs failed to properly complete"
  exit 1
fi

echo "*** Specs passed. Starting litmus"
echo

# Ensure fresh store directory
rm -rf /tmp/dav-file-store
mkdir /tmp/dav-file-store

# Run litmus test
bundle exec dav4rack --root /tmp/dav-file-store &

# Allow time for dav4rack to get started
sleep 3

DAV_PID=$?

if [ ! -f /tmp/litmus/litmus-0.14.tar.gz ]; then
  mkdir -p /tmp/litmus
  cd /tmp/litmus
  curl -O https://notroj.github.io/litmus/litmus-0.14.tar.gz
  tar -xzf litmus-0.14.tar.gz
  cd /tmp/litmus/litmus-0.14
  ./configure
fi

cd /tmp/litmus/litmus-0.14
make URL=http://localhost:3000/ check

LITMUS=$?

kill $DAV_PID

if [ $? -ne 0 ] ; then
  echo
  echo "*** Litmus failed to properly complete"
  exit 1
fi
