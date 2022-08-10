# Homebrew PHP version switcher
[Homebrew](https://brew.sh/) [PHP](https://php.net/) version switcher is a simple script to switch between [homebrew](https://brew.sh) installed [php](https://php.net/) versions for users using macOS.

## Caveats
### macOS
This script is working only on macOS and it was tested only on Monterey. It may work on Big Sur and even older versions like Catalina and Mojave but you have to use it caution.

### Apache
For best experience use [Homebrew Apache 2.x](https://formulae.brew.sh/formula/httpd) version instead of macOS built-in [Apache](https://httpd.apache.org/).

### PHP versions
This script will automatically detect which php versions are installed on your machine via [homebrew](https://brew.sh)

To install legacy php versions (like 5.6) you can use [shivammathur/homebrew-php](https://github.com/shivammathur/homebrew-php).

## Installation
```sh
git clone git@github.com:gtsvetanov/brew-php-switcher.git ./
cd brew-php-switcher
chmod +x brew-php-switcher.sh
mv brew-php-switcher.sh /usr/local/bin/brew-php-switcher
```

## Usage
```sh
brew-php-switcher <version> [-a | -f | -v | -h] 
```

### Options
`-a|--apache` - This option will change your [Apache 2.x](https://httpd.apache.org/) configuration
```sh
# Setting CLI php version 8.1 and change Apache configuration to use the same version
brew-php-switcher 8.1 -a 
```

`-f|--fpm` - This option will change your [PHP-FPM](https://www.php.net/manual/en/install.fpm.php) configuration
```sh
# Setting CLI php version 8.1 and PHP-FPM to use the same version
brew-php-switcher 8.1 -f 
```

`-v|--valet` - This option will change your [Laravel Valet](https://laravel.com/docs/master/valet) configuration
```sh
# Setting CLI php version 8.1 and Laravel Valet to use the same version
brew-php-switcher 8.1 -v 
```

`-h|--help` - This option will print help message
```sh
# Prints help message
brew-php-switcher -h
```

### Examples
```sh
# Changes CLI / Apache / PHP-FPM and Laravel Valet to 5.6
brew-php-switcher 5.6 -a -f -v

# Changes CLI / Apache / PHP-FPM and Laravel Valet to 7.0
brew-php-switcher 7.0 -a -f -v

# Changes CLI / Apache / PHP-FPM and Laravel Valet to 7.1
brew-php-switcher 7.1 -a -f -v

# Changes CLI / Apache / PHP-FPM and Laravel Valet to 7.2
brew-php-switcher 7.2 -a -f -v

# Changes CLI / Apache / PHP-FPM and Laravel Valet to 7.3
brew-php-switcher 7.3 -a -f -v

# Changes CLI / Apache / PHP-FPM and Laravel Valet to 7.4
brew-php-switcher 7.4 -a -f -v

# Changes CLI / Apache / PHP-FPM and Laravel Valet to 8.0
brew-php-switcher 8.0 -a -f -v

# Changes CLI / Apache / PHP-FPM and Laravel Valet to 8.1
brew-php-switcher 8.1 -a -f -v
```

## Helpful links
- [philcook/brew-php-switcher](https://github.com/philcook/brew-php-switcher)
- [Easy Brew PHP-FPM switch](https://gist.github.com/rozsival/10289d1e2006c68009ace0478306ecd2)
- [macOS Monterey Apache multiple php versions](https://getgrav.org/blog/macos-monterey-apache-multiple-php-versions)
