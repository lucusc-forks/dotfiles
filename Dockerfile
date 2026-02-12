FROM ubuntu:24.04

# Prevent interactive prompts during apt-get install (e.g. tzdata)
ENV DEBIAN_FRONTEND=noninteractive
ARG TZ=America/Denver
ENV TZ=${TZ}

# Install minimal dependencies needed for install.sh
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    sudo \
    zsh \
    build-essential \
    file \
    locales \
    && rm -rf /var/lib/apt/lists/*

# Set up locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8

# Create a test user
RUN useradd -ms /bin/zsh user && \
    echo "user ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/user && \
    chmod 0440 /etc/sudoers.d/user

USER user:user
WORKDIR /home/user

# Copy dotfiles into the container
COPY --chown=user:user . /home/user/dotfiles

CMD ["/bin/zsh"]
