#!/bin/bash
cd "$(dirname "$0")"

syncOne() {
  mkdir -p $1
  pushd $1
  rsync -aizLh ../Askowl/$1/Assets/Askowl/$1/Documentation/ .
  if [[ Askowl-$1.md -nt index.html ]]; then
    cp -f Askowl-$1.md index.md
  fi
  doxygen doxyfile
  rm *.meta
  rm *.tmp
  popd
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

# [Executive Summary](http://www.askowl.net/unity-package)

Here lies the Documentation Executive Summary

## [Unity3d FAQ](Unity-FAQ)
EOF

for d in ../Askowl/*    
    do    
        dirName=$(basename $d)
        syncOne $dirName
    done

git add -A
git commit -m "$(date)"
git pull --commit --no-edit
git push
