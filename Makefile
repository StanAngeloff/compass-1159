VENDOR_PATH := $(CURDIR)/vendor

.PHONY: default install-ruby-dependencies install clean

# Do nothing if `make` invoked with no arguments.
default:
	@/bin/echo "No default '$(MAKE)' target configured. Did you mean any of the following:"
	@/bin/echo
	@cat '$(firstword $(MAKEFILE_LIST))' | grep '^[[:alnum:] \-]\+:' | sed -e 's/:.*//g' | sort -u | tr "\\n" ' ' | fold -sw 76 | sed -e 's#^#    #g'
	@/bin/echo
	@exit 1

# Check if a given command is available and exit if it's missing.
required-dependency =                                              \
	/bin/echo -n "Checking if '$(1)' is available... " ;             \
	$(eval COMMAND := which '$(1)')                                  \
	if $(COMMAND) >/dev/null; then                                   \
		$(COMMAND) ;                                                   \
	else                                                             \
		/bin/echo "command failed:" ;                                  \
		/bin/echo ;                                                    \
		/bin/echo "    $$ $(COMMAND)" ;                                \
		/bin/echo ;                                                    \
		/bin/echo "You must install $(2) before you could continue." ; \
		/bin/echo "On Debian-based systems, you may want to try:" ;    \
		/bin/echo ;                                                    \
		/bin/echo "    $$ [sudo] apt-get install $(3)" ;               \
		/bin/echo ;                                                    \
		exit 1;                                                        \
	fi

# Install a RubyGem if it's not present on the system.
install-ruby-gem-if-missing =                                                                      \
	/bin/echo -n "Checking if '$(1)' RubyGem is available... " ;                                     \
	$(eval GEM_VERSION := ruby -rubygems -e "puts Gem::Specification::find_by_name('$(1)').version") \
	if $(GEM_VERSION) 2>&1 1>/dev/null; then                                                         \
		$(GEM_VERSION) ;                                                                               \
	else                                                                                             \
		/bin/echo "nope." ;                                                                            \
		/bin/echo -n "Installing '$(1)' RubyGem... " ;                                                 \
		gem install --remote --no-ri --no-rdoc '$(1)' 1>/dev/null || (                                 \
			/bin/echo                                                                                                               ; \
			/bin/echo "Failed to install '$(1)' RubyGem."                                                                           ; \
			/bin/echo                                                                                                               ; \
			/bin/echo "On Debian-based systems, if you receive permission issues, please run the following commands and try again:" ; \
			/bin/echo "    $$ [sudo] mkdir -p /var/lib/gems"                                                                        ; \
			/bin/echo "    $$ [sudo] chown -R `whoami`:users /var/lib/gems /usr/local"                                              ; \
			/bin/echo                                                                                                               ; \
		) ;              \
		$(GEM_VERSION) ; \
	fi

BUNDLE_GEMS := $(shell bundle check 1>/dev/null 2>&1 && echo '.bundle' || echo '.fail')

# Install all RubyGems from Gemfile using Bundler.
install-ruby-dependencies: $(BUNDLE_GEMS)
$(BUNDLE_GEMS):
	@$(call required-dependency,ruby,Ruby,ruby1.9.3)
	@$(call required-dependency,gem,RubyGems,rubygems1.8)
	@$(call install-ruby-gem-if-missing,bundler)
	@$(call required-dependency,bundle,Bundler,ruby-bundler)
	@/bin/echo -n 'Installing RubyGem project-specific dependencies... '
	@bundle install --path '$(VENDOR_PATH)' --binstubs '$(VENDOR_PATH)/.bin/' 1>/dev/null
	@/bin/echo 'OK'

# Bootstrap a development environment.
install-development: install-ruby-dependencies

install: install-development

clean:
	@$(call required-dependency,git,Git,git-core)
	@git clean -dfx


# vim: ts=2 sw=2 noet
