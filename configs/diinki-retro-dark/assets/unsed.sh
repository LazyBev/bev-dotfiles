#!/bin/sh
sed -i \
         -e 's/rgb(0%,0%,0%)/#141216/g' \
         -e 's/rgb(100%,100%,100%)/#d8cab8/g' \
    -e 's/rgb(50%,0%,0%)/#27232b/g' \
     -e 's/rgb(0%,50%,0%)/#AC82E9/g' \
 -e 's/rgb(0%,50.196078%,0%)/#AC82E9/g' \
     -e 's/rgb(50%,0%,50%)/#27232b/g' \
 -e 's/rgb(50.196078%,0%,50.196078%)/#27232b/g' \
     -e 's/rgb(0%,0%,50%)/#d8cab8/g' \
	"$@"
