#!/bin/bash
USERNAME=${USERNAME:-gardsted}
USERMAIL=${USERMAIL:-gardsted@gmail.com}
PACKAGE=$1
mkdir $PACKAGE
cd $PACKAGE

# -------------------git repo -------------------
[ -d ".git" ] && exit || (
    git init -q .
    git checkout -b master
    #git checkout -b develop
    git checkout -b development
    git config gitflow.branch.develop development
    git config user.email ${USERMAIL}
    git config user.name ${USERNAME}
    git flow init -d
    git flow feature start 0000-initializing-git-repo
    git config --list
)
# ------------------ ignores --------------------

git add . || exit 1
git commit -m "created package $PACKAGE"
echo "venv
docs/build
*.egg-info
*.p12
*.cert
*.secret
" > .gitignore
git add .
git commit -m "ignore in $PACKAGE"
mkdir $PACKAGE docs tests integrationtests
touch ${PACKAGE}/__init__.py
(cat <<EOF
import logging

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger("${PACKAGE}")
[
    logging.getLogger(i).setLevel(logging.WARNING) 
    for i in logging.root.manager.loggerDict.keys()
    if not i == "${PACKAGE}"
]


if __name__ == '__main__':
    logger.info("starting")
    logger.info("stopping")
EOF
) > ${PACKAGE}/__main__.py
git add --all #$PACKAGE docs docs/source tests integrationtests
git commit -m "added $PACKAGE and other generated files and folders"
# ----------------- readme and version -----------
(cat <<EOF
# the ${PACKAGE} python module 
EOF
) > README.md
echo 0.0.1 > VERSION

# ------------------ setup.py --------------------

(cat <<EOF
#!/usr/bin/env python
import os
import sys
from setuptools import setup, find_packages
from version import version
rootdir = os.path.abspath(os.path.dirname(__file__))
name = "${PACKAGE}"
long_description = open(os.path.join(rootdir, 'README.md')).read().strip()
VERSION = open(os.path.join(rootdir, 'VERSION')).read().strip()
setup(name='python-' + name,
      version=VERSION,
      description='${PACKAGE}',
      long_description=long_description,
      url='',
      author='gardsted',
      author_email='gardsted@gmail.com',
      license='MPL',
      classifiers=[
          'Development Status :: 1 - Planning',
          'Environment :: Console',
          'License :: OSI Approved :: Mozilla Public License',
          'Natural Language :: English',
          'Operating System :: OS Independent',
          'Programming Language :: Python :: 3',
          'Programming Language :: Python :: 3.6',
      ],
      keywords='mail',
      packages=["${PACKAGE}"]
)
EOF
) > setup.py



# ----------- requirements.txt ----------------

(cat <<EOF
Sphinx
recommonmark
EOF
) > requirements.txt

git add --all 
git commit -m "setup.py, VERSION and requirements.txt"
# ----------- virtual env ----------------------

python3 -m venv venv --clear
. venv/bin/activate
pip install -r requirements.txt
./venv/bin/python setup.py develop
git add . 


# ----------- sphinx docs ----------------------
pushd docs
sphinx-quickstart\
    -p poluko -a poluko -v 0.0.1 -r initial -l danish -l english -l german -l swedish\
    --suffix .md --master index --ext-autodoc --ext-todo --ext-ifconfig\
    --makefile --sep --dot _ --batchfile

(cat <<'EOF'
# At the bottom of conf.py - recommonmark
def setup(app):
    app.add_config_value('recommonmark_config', {
            'url_resolver': os.path.abspath,
            'auto_toc_tree_section': 'Contents',
            'enable_eval_rst': True,
            }, True)
    app.add_transform(AutoStructify)
EOF
) >> source/conf.py

sed -i -e '/^# -- Path setup --------------------------------------------------------------$/a \
import os\
import sys\
import recommonmark\
from recommonmark.transform import AutoStructify\
from recommonmark.parser import CommonMarkParser\
source_parsers = {\
    ".md": CommonMarkParser,\
}\
sys.path[0:0]=[\
    os.path.abspath("."),\
    os.path.abspath("../../'$PACKAGE'")\
]' source/conf.py

make html
popd

git add --all
git commit -m "finishing up $PACKAGE"
git checkout -b development
git flow feature finish --showcommands


