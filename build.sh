#!/bin/bash

# Script arguments
while [ $# -gt 0 ]; do
	case "$1" in
		--help)
		  help=1
		;;
		--pyslurm_version=*)
		  pyslurm_version="${1#*=}"
		  ;;
	  	--pyslurm_arguments=*)
		  pyslurm_arguments="${1#*=}"
		  ;;
	  	*)
		echo "** Invalid Argument **"
		exit 1
	esac
	shift
done

# Display help and exit
if [ "$help" ]
then
	echo "Slurm-rest-api build.sh"
	echo "Usage:"
	echo "            bash build.sh [option]=[param] [option]=[param] ..."
	echo "options:"
	echo "            --help                            Shows this help page."
	echo "            --pyslurm_version                 Use a specific version of pyslurm. Defaults to use the pypi version 17.11.0 via pip"
	echo "            --pyslurm_arguments               PySlurm build arguments for installation. See github.com/Pyslurm/pyslurm for more information on available arguments. --pyslurm_version must be set to use additional pyslurm arguments."
	echo ""
	echo "example:    Build for slurm version 18.08.0 by using 18.08.0 and"
	echo '            bash build.sh --pyslurm_version="18.08.0"'
	echo ""
	exit 0
fi

# Clean up from any previous build
echo "Removing conda environment if it exists"
conda env remove --prefix env  --yes
# rc=$?; if [[ $rc != 0 ]]; then echo "error: slurm-rest-api could not create a conda environment. Do you have conda installed?"; exit $rc; fi

echo "Removing pyslurm install if exists in directory"
rm -rf pyslurm-install/

# Setup a fresh environment to install into
echo "Creating conda environment"
conda create --prefix env python=2.7 --yes
rc=$?; if [[ $rc != 0 ]]; then echo "error: slurm-rest-api could not create a conda environment. Do you have conda installed?"; exit $rc; fi

echo "Activating conda environment"
source activate env/
rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi

echo ""
if [ "$pyslurm_version" ]; then
	echo "Downloading conda dependencies"
	conda install git mysql cython --yes
	rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi

	echo ""
	echo "Downloading pyslurm"
	mkdir pyslurm-install
	rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi

	cd pyslurm-install
	git clone https://github.com/PySlurm/pyslurm.git
	rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi
	
	cd pyslurm
	git checkout $pyslurm_version
	rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi

	python setup.py build $pyslurm_arguments
	rc=$?; if [[ $rc != 0 ]]; then echo "error: slurm-rest-api failed to build pyslurm."; exit $rc; fi

	pip install .
	rc=$?; if [[ $rc != 0 ]]; then echo "error: slurm-rest-api failed to install pyslurm"; exit $rc; fi

	cd ..
	cd ..
else
	echo "Downloading conda dependencies"
        # Installing it this way might be broken, needs further testing.
        # It might need to import gcc and/or cython
	conda install mysql --yes
	rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi
fi

echo ""
echo "Installing slurm-rest-api via pip"

pip install -e .
rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi
echo "Slurm-rest-api successfully installed!"