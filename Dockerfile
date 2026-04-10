FROM fedora:latest

# Setup non-root user
RUN useradd -m -s /bin/zsh user
RUN echo "user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

WORKDIR /home/user/.dotfiles

COPY --chown=user init.sh .
COPY --chown=user scripts/ scripts/

# Make sure scripts have no syntax errors
RUN bash -n init.sh scripts/*.sh

RUN chmod +x init.sh scripts/*.sh

# System setup runs as root — no sudo needed
RUN HEADLESS=1 ./scripts/system.sh

# Pre-create brew prefix so user can install into it
RUN mkdir -p /home/linuxbrew/.linuxbrew
RUN chown -R user:user /home/linuxbrew

USER user

# User setup — system already done above
RUN NO_SYSTEM=1 HEADLESS=1 NO_STOW=1 ./init.sh

# Copy configs and stow them
COPY --chown=user . .
RUN rm -f ~/.zshrc
RUN eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" && just stow-all

# Trigger first-run zsh setup (installs oh-my-zsh)
RUN eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" && zsh -i -c exit
RUN zsh -c 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" && source ~/.zshrc'

WORKDIR /home/user

CMD ["zsh"]
