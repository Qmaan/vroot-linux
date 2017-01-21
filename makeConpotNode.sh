#!/bin/bash

if [ $# -ge 2 ] ; then

sed -i "s/USERMAIL/$1/" image/utilities.sh
sed -i "s/PASSWORDMAIL/$2/" image/utilities.sh

docker build -t imunes/vroot image/.

sed -i "s/$1/USERMAIL/" image/utilities.sh
sed -i "s/$2/PASSWORDMAIL/" image/utilities.sh

else

echo "
Proper usage : bash makeConpotNode.sh [gmail_username] [gmail_password]
"

fi
