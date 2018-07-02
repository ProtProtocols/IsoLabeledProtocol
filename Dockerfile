FROM veitveit/protprotocols_template

USER root

# Setup R
ADD DockerSetup/install_packages.R /tmp/
RUN Rscript /tmp/install_packages.R && rm /tmp/install_packages.R

# Install python packages
RUN pip3 install psutil && \
    pip3 install pandas

# Install Mono
RUN apt-get update \
 && apt-get install -y mono-complete \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*


# Install SearchGui and PeptideShaker
USER biodocker

RUN mkdir /home/biodocker/bin
RUN PVersion=1.16.17 && ZIP=PeptideShaker-${PVersion}.zip && \
    wget -q http://genesis.ugent.be/maven2/eu/isas/peptideshaker/PeptideShaker/${PVersion}/$ZIP -O /tmp/$ZIP && \
    unzip /tmp/$ZIP -d /home/biodocker/bin/ && rm /tmp/$ZIP && \
    bash -c 'echo -e "#!/bin/bash\njava -jar /home/biodocker/bin/PeptideShaker-${PVersion}/PeptideShaker-${PVersion}.jar $@"' > /home/biodocker/bin/PeptideShaker && \
    chmod +x /home/biodocker/bin/PeptideShaker
    
RUN SVersion=3.2.20 && ZIP=SearchGUI-${SVersion}-mac_and_linux.tar.gz && \
    wget -q http://genesis.ugent.be/maven2/eu/isas/searchgui/SearchGUI/${SVersion}/$ZIP -O /tmp/$ZIP && \
    tar -xzf /tmp/$ZIP -C /home/biodocker/bin/ && \
    rm /tmp/$ZIP && \
    bash -c 'echo -e "#!/bin/bash\njava -jar /home/biodocker/bin/SearchGUI-$SVersion/SearchGUI-$SVersion.jar $@"' > /home/biodocker/bin/SearchGUI && \
    chmod +x /home/biodocker/bin/SearchGUI

ENV PATH /home/biodocker/bin/SearchGUI:/home/biodocker/bin/PeptideShaker:$PATH

WORKDIR /home/biodocker/

COPY Example.ipynb .
#COPY Example_isobar.ipynb .
RUN mkdir Scripts
COPY Scripts/ Scripts/
COPY Test/iTRAQCancer.mgf IN
COPY Test/sp_human.fasta IN

USER root

RUN chown -R biodocker .

RUN ln -s /data data

# Testing
#RUN pip install jupyter_contrib_nbextensions && jupyter contrib nbextension install --user && pip ins#tall jupyter_nbextensions_configurator && jupyter nbextensions_configurator enable --sys-prefix 
#COPY notebook.json .jupyter/nbconfig/

USER biodocker


# Run example notebook to have the results ready
#RUN jupyter nbconvert --to notebook --ExecutePreprocessor.timeout=3600 --execute Example.ipynb && mv Example.nbconvert.ipynb Example.ipynb
RUN jupyter trust Example.ipynb
