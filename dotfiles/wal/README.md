wal templates dotfiles package

This package manages your pywal templates.

- Home path: ~/.config/wal/templates
- Repo path: dotfiles/wal/.config/wal/templates

How to store (adopt) your current templates into this repo:

- One-off for this package:
    STOW_ADOPT=1 DOTFILES_REPLACE=1 bash scripts/80_dotfiles.sh wal

This will move files from ~/.config/wal/templates into this package directory while creating the proper symlinks back to your home.

How to restore templates from the repo to your home (fresh setup):

- Run the general dotfiles script (it auto-detects all packages, including wal):
    bash scripts/80_dotfiles.sh

Notes:
- If you prefer to only apply this package:
    bash scripts/80_dotfiles.sh wal
- Set DOTFILES_REPLACE=0 to prevent overwriting existing files in your home.