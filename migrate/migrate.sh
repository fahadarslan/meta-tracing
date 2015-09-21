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
    echo -en "\nTransferring files from branch: ${branch}\n\n"
    target_dir=$(echo "${branch}" | sed -e s/"upstream\/"//g -e s/"release\/"//g)
    echo "Target directory for branch: ${target_dir}"
    files=$(git ls-tree -ztr --name-only --full-tree ${branch}|xargs -0 -n 1 -I{} echo -en "{}\n"|grep -v "README.md" )
    echo -en "Found the following manifest files on the branch:\n${files}\n"
    for file in ${files}; do
        dir="$(dirname ${file})"
        base_file=$(basename ${file})
        echo "Check if ./${base_file} exists"
        if [ ! -e "${base_file}" ]; then
            echo "./${base_file} does not exist"
            echo "Creating directory for: ${target_dir}/${file}"
            mkdir -pv "${target_dir}/${dir}"
            echo "In git, adding ${branch}:${file} here: ${target_dir}/${file}"
            git show "${branch}:${file}" > "${target_dir}/${file}"
            git add "${target_dir}/${file}"
        else
            echo "./${base_file} already exists!"
            echo "Check if ./${base_file} and ${branch}:${file} match"
            git show "${branch}:${file}" | diff -q - "${base_file}"
            rc=$?
            if [ 0 != ${rc} ]; then
                echo "File ${branch}:${file} doesn't match ${base_file}"
                echo -en "WARNING: conflicting versions of ${branch}:${file} detected\nAssuming one on master branch is for cedar\n"
                echo "Creating directory for: ${target_dir}/${file}"
                mkdir -pv "${target_dir}/${dir}"
                echo "In git, adding ${branch}:${file} here: ${target_dir}/${file}"
                git show "${branch}:${file}" > "${target_dir}/${file}"
                git add "${target_dir}/${file}"
            else
                echo "Creating directory for: ${target_dir}/${file}"
                mkdir -pv "${target_dir}/${dir}"
                echo "In git, moving ${base_file} to here: ${target_dir}/${dir}/${file}"
                git mv "${base_file}" "${target_dir}/${file}"
            fi
          fi
        echo ""
      done
    echo ""
  done

# I assume that any .xml (manifest files left in the root directory, are "cedar" specific.
echo "Moving the remaining manifests into the cedar release directory"
mkdir -pv cedar
for file in $(ls -1 *.xml); do
    echo "In git, moving ${file} to here: cedar/${file}"
    git mv "${file}" cedar
done

# Find all the .xml files with the include directive and re-write to new location
for file in $(find . -type f -name "*xml"); do
    # echo "Scanning ${file} for include directive"
    grep -q "<include name=" "${file}"
    rc=$?
    if [ 0 == ${rc} ]; then
        included_manifest="$(grep "<include name=" "${file}" | sed -e s/'.*include name="'// -e s/'".*$'//)"
        target_dir="$(dirname "${file}" | sed -e s/"\.\/"//g )"

        if [ -e "${target_dir}/${included_manifest}" ]; then
            echo "Adding ${target_dir} to include directive in: ${file}"
            sed -i -e s/'include name="'/'include name="'"${target_dir}\/"/ "${file}"
        else
            echo ""
            echo "WARNING: ${file} included ${included_manifest} which was not found in local directory . . .  searching other dirs"
            manifest=$(find * -type f -name "*.xml" -print|grep "${included_manifest}" )
            echo "Found ${manifest} to use in ${file}"
            manifest=$(echo "${manifest}" | sed -e s/"\.\/"// -e s/"\/"/"\\\\\/"/g )
            sed -i -e s/'include name=".*"'/'include name="'"${manifest}\""/ "${file}"
            echo ""
        fi
        git add "${file}"
    fi
done

git status -vsbu
