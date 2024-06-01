## dcape-app-template Makefile
## This file extends Makefile.app from dcape
#:

SHELL               = /bin/bash
CFG                ?= .env
CFG_BAK            ?= $(CFG).bak

#- App name
APP_NAME           ?= lemmy

#- Docker image name
IMAGE              ?= dessalines/lemmy-ui

#- Docker image tag
IMAGE_VER          ?= 0.19.3

#- lemmy docker image
LEMMY_IMAGE        ?= dessalines/lemmy
#- lemmy docker image tag
LEMMY_IMAGE_VER    ?= $(IMAGE_VER)

#- pict-rs docker image
PICTRS_IMAGE       ?= docker.io/asonix/pictrs
#- pict-rs docker image tag
PICTRS_IMAGE_VER   ?= 0.5.0
#- pict-rs API key
PICTRS_API_KEY     ?= $(shell openssl rand -hex 16; echo)

#- Hostname and port of the smtp server
SMTP_SERVER        ?=
#- Login name for smtp server
SMTP_USER          ?=
#- Password to login to the smtp server
SMTP_PASS          ?=
#- Address to send emails from, eg "noreply@your-instance.com"
SMTP_FROM          ?=
#- Whether or not smtp connections should use tls. Can be none, tls, or starttls
SMTP_TLS_TYPE      ?= none

USE_DB              = yes
ADD_USER            = yes

# ------------------------------------------------------------------------------

# if exists - load old values
-include $(CFG_BAK)
export

-include $(CFG)
export

# This content will be added to .env
define CONFIG_HJSON
  # Settings related to activitypub federation
  # Pictrs image server configuration.
  pictrs: {
    # Address where pictrs is available (for image hosting)
    url: "http://pictrs:8080/"
    # Set a custom pictrs API key. ( Required for deleting images )
    api_key: "$(PICTRS_API_KEY)"
  }
  # Email sending configuration. All options except login/password are mandatory
  email: {
    # Hostname and port of the smtp server
    smtp_server: "$(SMTP_SERVER)"
    # Login name for smtp server
    smtp_login: "$(SMTP_USER)"
    # Password to login to the smtp server
    smtp_password: "$(SMTP_PASS)"
    # Address to send emails from, eg "noreply@your-instance.com"
    smtp_from_address: "$(SMTP_FROM)"
    # Whether or not smtp connections should use tls. Can be none, tls, or starttls
    tls_type: "$(SMTP_TLS)"
  }
  # Parameters for automatic configuration of new instance (only used at first start)
  setup: {
    # Username for the admin user
    admin_username: "$(USER_NAME)"
    # Password for the admin user. It must be at least 10 characters.
    admin_password: "$(USER_PASS)"
    # Name of the site (can be changed later)
    site_name: "My Lemmy Instance"
    # Email for the admin user (optional, can be omitted and set later through the website)
    admin_email: "$(USER_EMAIL)"
  }
  # the domain name of your instance (mandatory)
  hostname: "$(APP_SITE)"
endef

# ------------------------------------------------------------------------------
# Find and include DCAPE_ROOT/Makefile
DCAPE_COMPOSE   ?= dcape-compose
DCAPE_ROOT      ?= $(shell docker inspect -f "{{.Config.Labels.dcape_root}}" $(DCAPE_COMPOSE))

ifeq ($(shell test -e $(DCAPE_ROOT)/Makefile.app && echo -n yes),yes)
  include $(DCAPE_ROOT)/Makefile.app
else
  include /opt/dcape/Makefile.app
endif

# ------------------------------------------------------------------------------

## Template support code, used once
use-template:

.default-deploy: prep

prep: lemmy.hjson
	@echo "Just to show we able to attach"
	[ -d volumes/pictrs ] || mkdir -p volumes/pictrs
	sudo chown -R 991:991 volumes/pictrs

lemmy.hjson:
	@echo "$$CONFIG_HJSON" > $@


getconfig:
	wget https://raw.githubusercontent.com/LemmyNet/lemmy-ansible/main/templates/docker-compose.yml
	wget https://raw.githubusercontent.com/LemmyNet/lemmy-ansible/main/examples/config.hjson -O lemmy.hjson
	wget https://raw.githubusercontent.com/LemmyNet/lemmy-ansible/main/templates/nginx_internal.conf
	wget https://raw.githubusercontent.com/LemmyNet/lemmy-ansible/main/files/proxy_params
