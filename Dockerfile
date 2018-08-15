FROM veitveit/protprotocols_template

USER root

# Install Mono - note: This must run before the R setup as packages required by R are
# installed as well.
RUN apt-get update \
 && apt-get install -y mono-complete libxml2-dev libnetcdf-dev \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Setup R
ADD DockerSetup/install_packages.R /tmp/
RUN Rscript /tmp/install_packages.R && rm /tmp/install_packages.R

# Install python packages
RUN pip3 install psutil && \
    pip3 install pandas && \
    pip3 install tzlocal


# Install SearchGui and PeptideShaker
USER biodocker

RUN mkdir /home/biodocker/bin
RUN PVersion=1.16.27 && ZIP=PeptideShaker-${PVersion}.zip && \
    wget -q http://genesis.ugent.be/maven2/eu/isas/peptideshaker/PeptideShaker/${PVersion}/$ZIP -O /tmp/$ZIP && \
    unzip /tmp/$ZIP -d /home/biodocker/bin/ && rm /tmp/$ZIP && \
    bash -c 'echo -e "#!/bin/bash\njava -jar /home/biodocker/bin/PeptideShaker-${PVersion}/PeptideShaker-${PVersion}.jar $@"' > /home/biodocker/bin/PeptideShaker && \
    chmod +x /home/biodocker/bin/PeptideShaker
    
RUN SVersion=3.3.3 && ZIP=SearchGUI-${SVersion}-mac_and_linux.tar.gz && \
    wget -q http://genesis.ugent.be/maven2/eu/isas/searchgui/SearchGUI/${SVersion}/$ZIP -O /tmp/$ZIP && \
    tar -xzf /tmp/$ZIP -C /home/biodocker/bin/ && \
    rm /tmp/$ZIP && \
    bash -c 'echo -e "#!/bin/bash\njava -jar /home/biodocker/bin/SearchGUI-$SVersion/SearchGUI-$SVersion.jar $@"' > /home/biodocker/bin/SearchGUI && \
    chmod +x /home/biodocker/bin/SearchGUI

ENV PATH /home/biodocker/bin/SearchGUI:/home/biodocker/bin/PeptideShaker:$PATH

WORKDIR /home/biodocker/

COPY Example.ipynb .
COPY Description.ipynb .
#COPY Example_isobar.ipynb .
RUN mkdir Scripts
COPY Scripts/ Scripts/
COPY Test/iTRAQCancer.mgf IN
COPY Test/sp_human.fasta IN
COPY Test/exp_design_example.tsv IN

USER root

RUN chown -R biodocker .

# copy worflow diagram
COPY ShortWorkflow.svg misc

# To allow use of folder /data mounted to the outside
RUN ln -s /data data

# Testing
#RUN pip install jupyter_contrib_nbextensions && jupyter contrib nbextension install --user && pip ins#tall jupyter_nbextensions_configurator && jupyter nbextensions_configurator enable --sys-prefix 
#COPY notebook.json .jupyter/nbconfig/

USER biodocker


# Run example notebook to have the results ready
#RUN jupyter nbconvert --to notebook --ExecutePreprocessor.timeout=3600 --execute Example.ipynb && mv Example.nbconvert.ipynb Example.ipynb
RUN jupyter trust Example.ipynb
