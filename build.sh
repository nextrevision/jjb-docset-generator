#!/bin/bash

CWD=$(pwd)
DOCSET_NAME="Jenkins_Job_Builder"

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

# tar results
cd $CWD
tar --exclude='.DS_Store' -cvzf "${DOCSET_NAME}.tgz" "${DOCSET_NAME}.docset"

# display results
echo "Created ${DOCSET_NAME}.tgz"
echo "JJB Version: ${JJB_VERSION}"

# cleanup
deactivate
rm -Rf jenkins-job-builder
