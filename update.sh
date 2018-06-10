#!/bin/bash
cd "$(dirname "$0")"

syncOne() {
  mkdir -p $1
  rsync -aizLh ../$1/Assets/Askowl/$1/Documentation/ $1
  if [[ $1/Askowl-$1.md -nt $1/index.html ]]; then
    cp -f $1/Askowl-$1.md $1/index.md
  fi
  echo "## [$1]($1/)" >>index.md
  echo "Here there be $1" dragons >>index.md
}

cat > "index.md" << EOF
---
title:  Askowl Unity Documentation
description: Documentation for all the Askowl Unity3D Packages
---
* Table of Contents
{:toc}

[Executive Summary](http://www.askowl.net/unity-package)

Here lies the Documentation Executive Summary
EOF

for d in ../*    
    do    
        dirName=$(basename $d)
        [[ $dirName =~ ^(Documentation)$ ]] && continue
        syncOne $dirName
    done
