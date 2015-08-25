# QuantEcon Docker Image (for tmpnb server)
# User: quantecon
# Currently compiling a single container
# Future Work:
#   1. Build base/ r/ jl/ and py/ environments if need to be more lightweight

FROM debian:jessie

MAINTAINER QuantEcon Project <quantecon@googlegroups.com>

USER root

ENV DEBIAN_FRONTEND noninteractive

#-Install Dependancies for Fully Functional NB Server-#

RUN apt-get update && apt-get install -yq --no-install-recommends \
    git \
    vim \
    wget \
    build-essential \
    python-dev \
    ca-certificates \
    bzip2 \
    unzip \
    libsm6 \
    pandoc \
    texlive-latex-base \
    texlive-latex-extra \
    texlive-fonts-extra \
    texlive-fonts-recommended \
    supervisor \
    sudo \
    julia \
    libnettle4 \
    libxrender1 \
    fonts-dejavu \
    gfortran \
    gcc \
    && apt-get clean

#-Anaconda-#
ENV CONDA_DIR /opt/conda

# Install conda for the quantecon user only (this is a single user container)
RUN echo 'export PATH=$CONDA_DIR/bin:$PATH' > /etc/profile.d/conda.sh && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda3-3.9.1-Linux-x86_64.sh && \
    /bin/bash /Miniconda3-3.9.1-Linux-x86_64.sh -b -p $CONDA_DIR && \
    rm Miniconda3-3.9.1-Linux-x86_64.sh && \
    $CONDA_DIR/bin/conda install --yes conda==3.10.1

# Run our docker images with a non-root user as a security precaution.
# quantecon is our user
RUN useradd -m -s /bin/bash quantecon
RUN chown -R quantecon:quantecon $CONDA_DIR

EXPOSE 8888

USER quantecon
ENV HOME /home/quantecon
ENV SHELL /bin/bash
ENV USER quantecon
ENV PATH $CONDA_DIR/bin:$PATH
WORKDIR $HOME

RUN conda install --yes ipython-notebook terminado && conda clean -yt

RUN ipython profile create

#-Workaround for issue with ADD permissions-#
USER root
ADD profile_default/ /home/quantecon/.ipython/profile_default
ADD templates/ /srv/templates/
RUN chmod a+rX /srv/templates
RUN chown quantecon:quantecon /home/quantecon -R
USER quantecon

#-Expose our custom setup to the installed ipython (for mounting by nginx)-#
RUN cp /home/quantecon/.ipython/profile_default/static/custom/* /opt/conda/lib/python3.4/site-packages/IPython/html/static/custom/

#-Add QuantEcon Notebooks-#
USER root
ADD notebooks/ /home/quantecon/
RUN chown -R quantecon:quantecon /home/quantecon
USER quantecon

# Python packages
RUN conda install --yes numpy pandas scikit-learn scikit-image matplotlib scipy seaborn sympy cython patsy statsmodels cloudpickle dill numba bokeh jupyter && conda clean -yt
RUN pip install quantecon

# Now for a python2 environment (removed for now)
#RUN conda create -p $CONDA_DIR/envs/python2 python=2.7 ipython numpy pandas scikit-learn scikit-image matplotlib scipy seaborn sympy cython patsy statsmodels cloudpickle dill numba bokeh && conda clean -yt
#RUN $CONDA_DIR/envs/python2/bin/python $CONDA_DIR/envs/python2/bin/ipython kernelspec install-self --user

# R packages
RUN conda config --add channels r
RUN conda install --yes r-irkernel r-plyr r-devtools r-rcurl r-dplyr r-ggplot2 r-caret rpy2 r-tidyr r-shiny r-rmarkdown r-forecast r-stringr r-rsqlite r-reshape2 r-nycflights13 r-randomforest && conda clean -yt

# IJulia and Julia packages
RUN julia -e 'Pkg.add("IJulia")'
RUN julia -e 'Pkg.add("Gadfly")' && julia -e 'Pkg.add("RDatasets")'
RUN julia -e 'Pkg.add("QuantEcon")'

# Extra Kernels
RUN pip install --user bash_kernel

# Convert notebooks to the current format
RUN find . -name '*.ipynb' -exec ipython nbconvert --to notebook {} --output {} \;
RUN find . -name '*.ipynb' -exec ipython trust {} \;

CMD ipython notebook
