#!/bin/sh

base="/opt/magic_mirror"
default_dir="${base}/modules/default"
config_dir="${base}/config"
css_dir="${base}/css"

_info() {
  echo "[entrypoint $(date +%T.%3N)] $1"
}

[ -z "$TZ" ] && export TZ="$(wget -qO - http://geoip.ubuntu.com/lookup | sed -n -e 's/.*<TimeZone>\(.*\)<\/TimeZone>.*/\1/p')"

if [ -z "$TZ" ]; then
  _info "***WARNING*** could not set timezone, please set TZ variable in docker-compose.yml, see https://khassel.gitlab.io/magicmirror/configuration/#timezone"
else
  sudo ln -fs /usr/share/zoneinfo/$TZ /etc/localtime
  sudo sh -c "echo $TZ > /etc/timezone"
fi

[ ! -d "${default_dir}" ] && MM_OVERRIDE_DEFAULT_MODULES=true

if [ "${MM_OVERRIDE_DEFAULT_MODULES}" = "true" ]; then
  _info "copy default modules to host"
  sudo rm -rf ${default_dir}
  sudo mkdir -p ${default_dir}
  sudo cp -r ${base}/mount_ori/modules/default/. ${default_dir}/
fi

sudo mkdir -p ${config_dir}

sudo mkdir -p ${css_dir}

[ ! -f "${css_dir}/main.css" ] && MM_OVERRIDE_CSS=true

if [ "${MM_OVERRIDE_CSS}" = "true" ]; then
  _info "copy css files to host"
  sudo cp ${base}/mount_ori/css/* ${css_dir}/
fi

# create css/custom.css file https://github.com/MichMich/MagicMirror/issues/1977
[ ! -f "${css_dir}/custom.css" ] && sudo touch ${css_dir}/custom.css

_info "chown modules and config folder"
sudo chown -R node:node ${base}/modules &
sudo chown -R node:node ${config_dir}
sudo chown -R node:node ${css_dir}

if [ ! -f "${config_dir}/config.js" ]; then
  _info "copy default config.js to host"
  cp ${base}/mount_ori/config/config.js.sample ${config_dir}/config.js
fi

if [ "$MM_SHOW_CURSOR" = "true" ]; then
  _info "enable mouse cursor"
  sed -i "s|  cursor: .*;|  cursor: auto;|" ${base}/css/main.css
fi

[ -z "$MM_RESTORE_SCRIPT_CONFIG" ] || (${base}/create_restore_script.sh "$MM_RESTORE_SCRIPT_CONFIG" || true)

if [ "$StartEnv" = "test" ]; then
  set -e

  export NODE_ENV=test

  _info "start tests"

  Xvfb :99 -screen 0 1024x768x16 &
  export DISPLAY=:99

  cd ${base}

  echo "/mount_ori/**/*" >> .prettierignore
  npm run test:prettier
  npm run test:js
  npm run test:css
  npm run test:unit
  npm run test:e2e
  npm run test:electron
else
  _script=""
  if [ -f "start_script.sh" ]; then
    _script="${base}/start_script.sh"
  elif [ -f "config/start_script.sh" ]; then
    _script="${base}/config/start_script.sh"
  elif [ -f "/config/start_script.sh" ]; then
    _script="/config/start_script.sh"
  fi
  if [ -n "$_script" ]; then
    _info "executing script $_script"
    sudo chmod +x "$_script"
    . "$_script"
  fi

  if [ $# -eq 0 ]; then
    # if no params are provided, add defaults depending if electron is installed:
    if command -v node_modules/.bin/electron &> /dev/null; then
      _info "starting everything (this is bad)"
      exec env TZ=$TZ npm start
    else
      _info "starting server (this is good)"
      exec env TZ=$TZ npm run server
    fi
  else
    _info "starting args as provided (this is best): $@"
    exec env TZ=$TZ "$@"
  fi
fi
