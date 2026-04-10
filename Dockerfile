FROM fedora:latest

# Setup non-root user
RUN dnf install -y zsh
RUN useradd -m -s /bin/zsh user
RUN passwd -d user
RUN echo "user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# pre-create brew prefix so user can install into it
RUN mkdir -p /home/linuxbrew/.linuxbrew
RUN chown -R user:user /home/linuxbrew

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
