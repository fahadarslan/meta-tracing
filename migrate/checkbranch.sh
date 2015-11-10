#!/bin/bash

branches="\
upstream/meibp/2013 \
upstream/mel4/current \
upstream/next \
upstream/pcsim \
upstream/release/2013.03 \
upstream/release/2013.11 \
upstream/release/2013.11-adit \
upstream/release/2014.05 \
upstream/release/2014.12 \
upstream/release/5.0.0 \
upstream/release/6.0.0 \
upstream/release/meibp2013.05 \
upstream/release/meibp2013.08 \
upstream/veracruz/sand \
upstream/veracruz3/sand \
"

set noclobber

# For each branch above, process each manifest, .xml, file
for branch in ${branches}; do 
    echo -en "\nChecking manifest files from branch: ${branch}\n\n"
    target_dir=$(echo "${branch}" | sed -e s/"upstream\/"//g -e s/"release\/"//g)
    echo "Target directory for branch: ${target_dir}"
    files=$(git ls-tree -ztr --name-only --full-tree ${branch}|xargs -0 -n 1 -I{} echo -en "{}\n"|grep -v "README.md"|grep -v "_deprecated" )
    echo -en "Found the following manifest files on the branch:\n${files}\n"
    for file in ${files}; do
        dir="$(dirname ${file})"
        base_file=$(basename ${file})
        echo "Check if ./${target_dir}/${file} exists"
        if [ ! -e "${target_dir}/${file}" ]; then
            echo "FAILED: ${target_dir}/${file} doesn't exist"
            exit -1
        else
            echo "Checking for changes in ${branch}:${file}"
            git show "${branch}:${file}" | diff -q - "${target_dir}/${file}"
            rc=$?
            if [ 0 != ${rc} ]; then
                echo -e "\tFAILED: File ${branch}:${file} doesn't match ${target_dir}/${file}"
            else
                echo -e "\tPASSED: File ${branch}:${file} matches ${target_dir}/${file}"
            fi
          fi
        echo ""
      done
    echo ""
  done
