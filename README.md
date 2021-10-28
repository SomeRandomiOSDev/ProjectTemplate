# ProjectTemplate

[![License MIT](https://img.shields.io/badge/license-MIT-success)](https://mit-license.org)

My custom project template for creating frameworks for iOS, macOS, tvOS and watchOS.

## Purpose

After setting up who knows how many new projects for each of my framework ideas, I've grown sick and tired of going through and configuring all of the new projects exactly the same way. Inevitably I forget a build setting or a configuration file here or there, so in true developer form I spent way too much time setting up this small project for the sole purpose of automating the setting up of new framework projects with identical configurations and settings. 

## Usage

The first step in utilizing this template is to first clone the repo:

```sh
git clone https://github.com/SomeRandomiOSDev/ProjectTemplate.git
```

The next step is to navigate into the newly cloned repo and configure it. First you'll want to begin by editing the `.../scripts/env.sh` file to update the various variables with the values that suit your environment. Next run the `.../scripts/config.sh` script and provide it the name (case sensitive) of the framework that you're creating. For example:

```sh
cd ProjectTemplate/scripts

./config.sh -name "MyNewFramework"
```

This script first copies the `ProjectTemplate` directory to a directory using the same name that you provided for your project in the same directory where the `ProjectTemplate` directory sits. Next it runs through this copy and substitutes the various placeholders in the file names and within the files themselves with the values provided in the `env.sh` script and with the name provided when running the `config.sh` script. 

After the script runs, you now have an empty project pre-configured for building various configurations for all supported platforms. 

## Author

Joe Newton, somerandomiosdev@gmail.com

## License

**ProjectTemplate** is available under the MIT license. See the `LICENSE` file for more info.
