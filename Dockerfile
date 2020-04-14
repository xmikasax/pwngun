FROM ubuntu:bionic

RUN dpkg --add-architecture i386 \
    && apt-get -y update \
    && apt-get -y install libc6:i386 libncurses5:i386 libstdc++6:i386 gcc-multilib g++-multilib

RUN apt-get -y install wget curl git autoconf automake libtool make unzip cmake texinfo patchelf strace ltrace zsh tmux tree nano netcat

RUN apt-get -y install python3

RUN apt-get -y install python3.8 \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 1 \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3.8 1

RUN apt-get -y install python3.8-dev python3.8-distutils

RUN mkdir -p /builds
WORKDIR /builds

RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
    && python3 get-pip.py

RUN wget https://ftp.gnu.org/gnu/gdb/gdb-9.1.tar.xz \
    && tar xvf gdb-9.1.tar.xz \
    && rm gdb-9.1.tar.xz \
    && cd gdb-9.1 \
    && mkdir build \
    && cd build \
    && ../configure --prefix=/usr --with-python=/usr/bin/python3.8 \
    && make -j 4 \
    && make -C gdb install

RUN wget -q -O- https://github.com/hugsy/gef/raw/dev/scripts/gef.sh | sh
RUN pip3 install ropper unicorn

RUN git clone https://github.com/keystone-engine/keystone.git \
    && cd keystone \
    && mkdir build \
    && cd build \
    && ../make-share.sh \
    && make install \
    && ldconfig

RUN pip3 install keystone-engine

RUN git clone https://github.com/radareorg/radare2.git \
    && cd radare2 \
    && sys/install.sh --install

RUN apt-get -y install ruby \
    && gem install one_gadget

ADD libc-database /libc-database
RUN /libc-database/libc-get

RUN pip install --upgrade git+https://github.com/Gallopsled/pwntools.git@dev
RUN mkdir -p ~/.pwntools-cache \
    && echo never > ~/.pwntools-cache/update

RUN sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" \
    && sed -ir 's/plugins=(git)/plugins=(git tmux zsh-completions zsh-autosuggestions zsh-syntax-highlighting history pip)/g' ~/.zshrc \
    && git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions \
    && git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions \
    && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting \
    && echo 'export PATH=/aux:/libc-database:$PATH' >> ~/.zshrc \
    && sed -i '1s/^/DISABLE_UPDATE_PROMPT=true\n/' ~/.zshrc \
    && chsh -s $(which zsh)

RUN rm -rf /builds
ADD craft_sploit.py sploit.py spl newa /aux/
