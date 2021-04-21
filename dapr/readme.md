install 
wget -q https://raw.githubusercontent.com/dapr/cli/master/install/install.sh -O - | /bin/bash

## install on kubernetes 
dapr init -k --enable-ha=true

