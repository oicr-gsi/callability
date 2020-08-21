FROM modulator:latest

MAINTAINER Fenglin Chen <f73chen@uwaterloo.ca>

# packages should already be set up in modulator:latest
USER root

# move in the yaml to build modulefiles from
COPY recipes/callability_recipe.yaml /modulator/code/gsi/recipe.yaml

# build the modules and set folder & file permissions
RUN ./build-local-code /modulator/code/gsi/recipe.yaml --initsh /usr/share/modules/init/sh --output /modules && \
	find /modules -type d -exec chmod 777 {} \; && \
	find /modules -type f -exec chmod 777 {} \;

# add the user
RUN groupadd -r -g 1000 ubuntu && useradd -r -g ubuntu -u 1000 ubuntu
USER ubuntu

# copy the setup file to load the modules at startup
COPY .bashrc /home/ubuntu/.bashrc

# set environment variables
ENV BEDTOOLS_ROOT="/modules/gsi/modulator/sw/Ubuntu18.04/bedtools-2.27"
ENV MOSDEPTH_ROOT="/modules/gsi/modulator/sw/Ubuntu18.04/mosdepth-0.2.9"
ENV PYTHON_ROOT="/modules/gsi/modulator/sw/Ubuntu18.04/python-3.7"

ENV PATH="/modules/gsi/modulator/sw/Ubuntu18.04/python-3.7/bin:/modules/gsi/modulator/sw/Ubuntu18.04/mosdepth-0.2.9/bin:/modules/gsi/modulator/sw/Ubuntu18.04/bedtools-2.27/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ENV MANPATH="/modules/gsi/modulator/sw/Ubuntu18.04/python-3.7/share/man"
ENV LD_LIBRARY_PATH="/modules/gsi/modulator/sw/Ubuntu18.04/python-3.7/lib"
ENV PKG_CONFIG_PATH="/modules/gsi/modulator/sw/Ubuntu18.04/python-3.7/lib/pkgconfig"
ENV PYTHONPATH="/modules/gsi/modulator/sw/Ubuntu18.04/python-3.7/lib/python3.7/site-packages"

CMD /bin/bash
