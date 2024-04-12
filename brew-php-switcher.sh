#!/bin/bash
# Author: Georgi Tsvetanov
# E-mail: spam@gtsvetanov.com
# Github: https://github.com/gtsvetanov
# Twitter: https://twitter.com/gtsvetanovcom

show_help() {
  # List php versions for help message
  versions_list=();
  for version in ${versions_map[*]}; do
    versions_list+=("$(echo "${version}" | cut -d "${DELIMITER}" -f1)")
  done

  versions_list_string=$(printf ", %s" "${versions_list[@]}")

  echo "Usage: switch.sh [<version>] [-a | -f | -v | -h]"
  echo "    <version>               one of: ${versions_list_string:2}"
  echo "    -a          --apache    set apache to use the same version"
  echo "    -f          --fpm       starts php fpm service and stop all other php fpm services"
  echo "    -v          --valet     set valet to use the same version"
  echo "    -h          --help      show help message"
  echo
}

change_apache_configuration() {
  load_module_string=$(echo "LoadModule ${module_name} ${apache_lib_path}" | sed 's#/#\\\/#g')
  load_module_string_commented="#${load_module_string}"

  # Check if apache module line already exists
  if grep -q "${load_module_string}" "${apache_config_file}"; then
    # Check if apache module line is already commented and the line doesn't match the selected version
    if ! grep -q "${load_module_string_commented}" "${apache_config_file}"; then
      if [[ "${version}" != "${selected_version}" ]]; then
        sed -i.bak -e "s/${load_module_string}/${load_module_string_commented}/" "${apache_config_file}"
      fi
    fi

    # If line is commented but matching selected version - uncomment it
    if [[ "${version}" == "${selected_version}" ]]; then
      sed -i.bak -e "s/${load_module_string_commented}/${load_module_string}/" "${apache_config_file}"
    fi
  else
    # If apache load module string doesn't exists then add it right after last of other modules
    apache_last_module_line=$(grep -n "LoadModule" "${apache_config_file}" | tail -n1 | cut -d ':' -f2 | sed 's#/#\\\/#g')

    # If version is the same as selected one then add it without comment at start of the line
    if [[ "${version}" == "${selected_version}" ]]; then
      sed -i.bak -e "s/${apache_last_module_line}/${apache_last_module_line}\n${load_module_string}/" "${apache_config_file}"
    # If version is not selected one then add it as a comment
    else
      sed -i.bak -e "s/${apache_last_module_line}/${apache_last_module_line}\n${load_module_string_commented}/" "${apache_config_file}"
    fi
  fi
}

# OSX version
osx_product_version=$(sw_vers -productVersion)
osx_major_version=$(echo "${osx_product_version}" | cut -d '.' -f1)
osx_minor_version=$(echo "${osx_product_version}" | cut -d '.' -f2)
osx_patch_version=$(echo "${osx_product_version}" | cut -d '.' -f3)
osx_version=$((osx_major_version * 10000 + osx_minor_version * 100 + ${osx_patch_version:-0}))

# Brew paths
brew_path=$(brew --prefix)
brew_etc_path="${brew_path}/etc"
brew_opt_path="${brew_path}/opt"

# Delimiters
SPACE=" "
DELIMITER="|"
VERSION_DELIMITER="."

# Flags
NA="na" # Not available

# Colors
ERROR="$(tput setaf 1)"
SUCCESS="$(tput setaf 2)"

# Get arrays of installed php versions and available fpm services
brew_packages=($(brew list --version | grep php | tr "${SPACE}" "${DELIMITER}"))
brew_services=($(brew services list | grep php | tr -s "${SPACE}" "${DELIMITER}"))

# Selected php version to use
selected_version="$1"

# Check if there is at least one php version installed via brew
if [[ ${#brew_packages[@]} -eq 0 ]]; then
  echo "${ERROR}✖ Not even a single PHP version is installed via brew"
  tput sgr0
  exit 1
fi

# Handle php versions and services
versions_map=()
for brew_package in ${brew_packages[*]}; do
  package_name=$(echo "${brew_package}" | cut -d "${DELIMITER}" -f1)
  package_version=$(echo "${brew_package}" | cut -d "${DELIMITER}" -f2)
  package_status="${NA}"

  for brew_php_service in ${brew_services[*]}; do
    service_name=$(echo "${brew_php_service}" | cut -d "${DELIMITER}" -f1)
    service_status=$(echo "${brew_php_service}" | cut -d "${DELIMITER}" -f2)

    if [[ "${service_name}" == "${package_name}" ]]; then
      package_status="${service_status}"
    fi
  done

  major_version=$(echo "${package_version}" | cut -d "${VERSION_DELIMITER}" -f1)
  minor_version=$(echo "${package_version}" | cut -d "${VERSION_DELIMITER}" -f2)
  version="${major_version}${VERSION_DELIMITER}${minor_version}"

  versions_map+=("${version}${DELIMITER}${package_name}${DELIMITER}${package_status}")
done

# Sort php versions
versions_map=($(for version in ${versions_map[*]}; do echo "$version"; done | sort))

# Handle passed options
apache_change=0
fpm_change=0
valet_change=0
while [[ $# -gt 0 ]]; do
  key="$1"
  case "${key}" in
    -a|--apache)
      apache_change=1
      ;;
    -f|--fpm)
      fpm_change=1
      ;;
    -v|--valet)
      valet_change=1
      ;;
    -h|--help)
      show_help
      exit
      ;;
  esac
  shift
done

# Check if version argument is empty
if [[ -z "${selected_version}" ]]; then
  echo "${ERROR}✖ version argument is required"
  show_help
  tput sgr0
  exit 1
fi

if [[ "${versions_map[*]}" == *"${selected_version}"* ]]; then
  echo "${SUCCESS}Switching PHP version to ${selected_version}"

  # Find package name by selected php version to use
  selected_package_name=""
  selected_package_status=""
  for version_value in ${versions_map[*]}; do
    if [[ ${version_value} == *"${selected_version}"* ]]; then
      selected_package_name=$(echo "${version_value}" | cut -d "${DELIMITER}" -f2)
      selected_package_status=$(echo "${version_value}" | cut -d "${DELIMITER}" -f3)
    fi
  done

  if [[ -z "${selected_package_name}" ]]; then
    echo "${ERROR}✖ Cannot find package name for version ${selected_version}"
    tput sgr0
    exit 1
  fi

  # Get full version directly from brew
  full_version=$(brew ls --versions "${selected_package_name}" | cut -d "${SPACE}" -f2)

  # Switch terminal php version to selected one
  brew unlink php &>/dev/null && brew unlink "${selected_package_name}" &>/dev/null && brew link --overwrite --force "${selected_package_name}" &>/dev/null

  echo "${SUCCESS}✔ Terminal php version switched to ${selected_version} (${full_version})"

  if [[ ${apache_change} -eq 1 ]]; then
    if brew list httpd &>/dev/null || [[ ${osx_version} -lt 12000 ]]; then
      if brew list httpd &>/dev/null; then
        echo "Brew version of Apache"
        apache_config_file="${brew_etc_path}/httpd/httpd.conf"
      else
        echo "Built-in Apache"
        apache_config_file="/etc/apache2/httpd.conf"
      fi

      for version_value in ${versions_map[*]}; do
        version=$(echo "${version_value}" | cut -d "${DELIMITER}" -f1)
        major_version=$(echo "${version}" | cut -d "${VERSION_DELIMITER}" -f1)

        # Set proper module name and lib file
        module_name="php5_module"
        lib_file="libphp5.so"
        if [[ "${major_version}" -ge 8 ]]; then
          module_name="php_module"
          lib_file="libphp.so"
        elif [[ "${major_version}" -ge 7 ]]; then
          module_name="php7_module"
          lib_file="libphp7.so"
        fi

        # Generate path to lib module and apache load module string
        apache_lib_path="${brew_opt_path}/php@${version}/lib/httpd/modules/${lib_file}"

        # Change apache configuration
        change_apache_configuration
      done

      # Restart apache
      if brew list httpd &>/dev/null; then
        brew services restart httpd &>/dev/null
      else
        sudo apachectl stop
        sudo apachectl start
      fi

      echo "${SUCCESS}✔ Apache php version switched to ${selected_version} (${full_version})"
    else
      echo "${ERROR}✖ Apache is not installed on this machine"
    fi
  fi

  if [[ ${fpm_change} -eq 1 ]]; then
    for version_value in ${versions_map[*]}; do
      version=$(echo "${version_value}" | cut -d "${DELIMITER}" -f1)
      package=$(echo "${version_value}" | cut -d "${DELIMITER}" -f2)
      status=$(echo "${version_value}" | cut -d "${DELIMITER}" -f3)

      if [[ "${version}" != "${selected_version}" && "${status}" == "started" ]]; then
        brew services stop "${package}" &>/dev/null
      fi
    done

    if [[ "${selected_package_status}" == "${NA}" ]]; then
      echo "${ERROR}✖ FPM service is not available for version ${selected_version} (${full_version})"
    elif [[ "${selected_package_status}" == "started" ]]; then
      echo "${SUCCESS}✔ FPM php version is already set to ${selected_version} (${full_version})"
    else
      brew services start "${selected_package_name}" &>/dev/null

      echo "${SUCCESS}✔ FPM php version was switched to ${selected_version} (${full_version})"
    fi
  fi

  if [[ ${valet_change} -eq 1 ]]; then
    if [[ $(hash valet 2>/dev/null) ]]; then
      valet use "${selected_version}" --force &>/dev/null

      echo "${SUCCESS}✔ Valet php version switched to ${selected_version} (${full_version})"
    else
      echo "${ERROR}✖ Valet is not installed on this machine"
    fi
  fi

  tput sgr0
  exit 0
else
  echo "${ERROR}✖ PHP version \"${selected_version}\" is not installed and not available"
  show_help
  tput sgr0
  exit 1
fi
