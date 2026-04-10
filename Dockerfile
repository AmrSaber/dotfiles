FROM fedora:latest

# Setup non-root user
RUN useradd -m -s /bin/zsh user && echo "user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER user
WORKDIR /home/user/.dotfiles

COPY --chown=user ./init.sh .

# Make sure init.sh has no syntax errors
RUN bash -n ./init.sh

# Run init.sh in headless mode
RUN chmod +x init.sh
RUN HEADLESS=1 NO_STOW=1 ./init.sh

COPY --chown=user . .

RUN rm -f ~/.zshrc
RUN eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" && just stow-all

# Trigger first-run zsh setup (installs oh-my-zsh)
RUN eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" && zsh -i -c exit

WORKDIR /home/user

CMD ["zsh"]
