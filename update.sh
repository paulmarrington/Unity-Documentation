#!/bin/bash
cd "$(dirname "$0")"

syncOne() {
  mkdir -p $1
  rsync -aizLh ../$1/Assets/Askowl/$1/Documentation/ $1
}

for d in ../*    
    do    
        dirName=$(basename $d)
        [[ $dirName =~ ^(Documentation)$ ]] && continue
        syncOne $dirName
    done
