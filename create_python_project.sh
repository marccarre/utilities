#!/bin/bash
#
# TITLE:
#   create_python_project.sh
#
# DESCRIPTION:
#   Creates a Python project, 
#   - compliant with nosetests, pip packaging, virtualenv, etc.
#   - with standardized and appropriate project structure
#   - with libraries clearly defined in a pip requirements.txt file
#   - with useful skeletons.
#
# DEPENDENCIES:
#   - Mac OSX 
#   - Python (brew install python or brew install python3)
#   - GNU sed (brew install gnu-sed)
#
# KNOWN BUGS:
#   - Script may work under other Unix-like operating systems, but you may need to change some commands' flags, e.g. sed -E becomes sed -r
#
# AUTHOR:
#   Marc Carre <carre.marc@gmail.com>
#
# CHANGELOG:
#   2015/01/09 (M.C.): Initial version of the script.
#

function read_input_or_default_to {
  default_value=$1
  parameter_name=$2
  read -p "> Enter $parameter_name: $default_value: " value
  value=${value:-$default_value}
  echo $value
}

function install_or_upgrade {
  library=$1
  while true; do
    read -p "> Do you wish to install or upgrade $library? [y/N]: " answer
    answer=${answer:-N}
    case $answer in
      [Yy]* ) pip install --upgrade $library; break;;
      [Nn]* ) break;;
      * ) echo "Please answer yes or no.";;
    esac
  done
}

function install_or_upgrade_with_version {
  library=$1
  while true; do
    read -p "> Do you wish to install or upgrade $library? [y/N]: " answer
    answer=${answer:-N}
    case $answer in
      [Yy]* )
        echo "$library is available in the below versions:"
        yolk -V $library
        read -p "> Which version of $library do you want to install? " version
        pip install --upgrade $library==$version;
        echo "$library==$version" >> requirements.txt
        break;;
      [Nn]* ) break;;
      * ) echo "Please answer yes or no.";;
    esac
  done
}

# Install or upgrade Python 'global' tools:
echo "Now installing or upgrading global Python tools..."
install_or_upgrade pip
install_or_upgrade distribute
install_or_upgrade virtualenv
install_or_upgrade yolk

# Create project:
echo "Now creating and configuring new Python project..."
read -p "> Enter project's name: " name
echo "Creating virtual environment for $name..."
virtualenv $name
cd $name

echo "Activating virtual environment (run 'deactivate' to exit it)..."
source bin/activate
virtualenv --relocatable .

# Install or upgrade Python 'local' (in virtualenv) tools:
echo "Now installing or upgrading global Python tools..."
install_or_upgrade_with_version nose
install_or_upgrade_with_version unittest2

# Create project's folder structure:
read -p "> Enter name of project's root package: " root_package
mkdir tests docs $root_package
touch $root_package/__init__.py
touch tests/__init__.py

# Create setup file and configure it:
version=$(read_input_or_default_to "0.1" "project's version")
read -p "> Enter project's description: " description
read -p "> Enter project's URL: " url
download_url=$(read_input_or_default_to $url "project's download URL")
author=$(read_input_or_default_to `whoami` "author's name")
read -p "> Enter author's email: " author_email

echo "try:
    from setuptools import setup
except ImportError:
    from distutils.core import setup

config = {
    'description': '$description',
    'author': '$author',
    'url': '$url',
    'download_url': '$download_url',
    'author_email': '$author_email',
    'version': '0.1',
    'install_requires': ['nose'],
    'packages': ['$root_package'],
    'scripts': [],
    'name': '$name'
}

setup(**config)
" > setup.py

class_name="$(tr '[:lower:]' '[:upper:]' <<< ${root_package:0:1})$(echo ${root_package:1} | gsed -r 's/([a-z]+)_([a-z])([a-z]+)/\1\U\2\L\3/')"
echo "from unittest2 import TestCase, main

class "$class_name"Test(TestCase):
    def setUp(self):
        pass

    def tearDown(self):
        pass

    def test_"$root_package"(self):
        self.fail('Not implemented test.')

if __name__ == '__main__':
    main()
" > tests/"$root_package"_test.py

echo "Python project '$name' now created."
