#!/bin/bash

CWD=$(pwd)
ONLINE_URL="http://docs.openstack.org/infra/jenkins-job-builder/"
DOCSET_NAME="Jenkins Job Builder"

# check for dependent tools
which git || { echo "Must have git installed"; exit 1; }
which sqlite3 || { echo "Must have sqlite3 installed"; exit 1; }
which virtualenv || { echo "Must have virtualenv installed"; exit 1; }
[ -x /usr/libexec/PlistBuddy ] || { echo "Must have PlistBuddy available"; exit 1; }

# clean workspace
[ -d jenkins-job-builder ] && rm -Rf jenkins-job-builder
rm -Rf *.tar.gz *.docset

# clone source
git clone https://github.com/openstack-infra/jenkins-job-builder

# install dependencies
cd jenkins-job-builder
virtualenv .venv
source .venv/bin/activate
pip install doc2dash
pip install -r requirements.txt
pip install -r test-requirements.txt
python setup.py install

JJB_VERSION=$(jenkins-jobs --version 2>&1 | cut -d ':' -f2)

# make docs
cd doc/
make html
doc2dash -n "${DOCSET_NAME}" -d ${CWD} build/html/

# quick and dirty way of adding plugins to search index
grep "<dt><a href=" build/html/genindex.html | grep "in module" | while read line; do
  path=$(echo $line | cut -d '"' -f2)
  name=$(echo $path | cut -d '#' -f2 | cut -d '.' -f2)
  sqlite3 "${CWD}/${DOCSET_NAME}.docset/Contents/Resources/docSet.dsidx" \
    "INSERT INTO searchIndex (name, type, path) VALUES ('${name}', 'Plugin', '${path}');"
done

# update plist with online url
/usr/libexec/PlistBuddy -c "add DashDocSetFallbackURL string ${ONLINE_URL}" \
  "${CWD}/${DOCSET_NAME}.docset/Contents/Info.plist"

# tar results
cd $CWD
tar --exclude='.DS_Store' -cvzf "${DOCSET_NAME// /_}.tgz" "${DOCSET_NAME}.docset"

# display results
echo "Created ${DOCSET_NAME// /_}.tgz"
echo "JJB Version: ${JJB_VERSION}"

# cleanup
deactivate
rm -Rf jenkins-job-builder
