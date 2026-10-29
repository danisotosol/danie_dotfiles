DOTFILES := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

# lnk SRC DEST. `ln -sf` would clobber a real file and `ln -snf` would nest inside a
# real directory, so anything at DEST that is not already a symlink is left alone.
LNK = lnk() { \
	if [ -e "$$2" ] && [ ! -L "$$2" ]; then \
		echo "skip: $$2 exists and is not a symlink" >&2; \
	else \
		mkdir -p "$$(dirname "$$2")" && ln -snf "$$1" "$$2" && echo "link: $$2 -> $$1"; \
	fi; \
}; lnk

.PHONY: link link-kitty link-nvim link-git link-claude

link: link-kitty link-nvim link-git link-claude

link-kitty:
	@$(LNK) "$(DOTFILES)/kitty/kitty.conf" "$(HOME)/.config/kitty/kitty.conf"

link-nvim:
	@$(LNK) "$(DOTFILES)/nvim" "$(HOME)/.config/nvim"

# An include instead of a symlink keeps identity and credential helpers out of the repo.
link-git:
	@if git config --global --get-all --type=path include.path | grep -qxF "$(DOTFILES)/git/config"; then \
		echo "git: include already present"; \
	else \
		git config --global --add include.path "$(DOTFILES)/git/config" && echo "git: include added"; \
	fi

link-claude:
	@for d in "$(DOTFILES)"/claude/skills/*/; do \
		d="$${d%/}"; $(LNK) "$$d" "$(HOME)/.claude/skills/$$(basename "$$d")"; \
	done
	@for f in "$(DOTFILES)"/claude/agents/*.md; do \
		$(LNK) "$$f" "$(HOME)/.claude/agents/$$(basename "$$f")"; \
	done
