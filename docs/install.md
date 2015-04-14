## Installing round-rb:


### Prerequisites:

* Ruby 2.1.5

### Linux (debian-based, tested on Ubuntu 14.04)

1. Install system dependencies (*this is the only time you need sudo!*)

  ```bash
  $ sudo apt-get install gcc make libffi-dev 
  ```

2. Install the client

  ```bash
  $ gem install round
  ```

 [[back]](../README.md)

### Mac OSX:

1.  Install Xcode Command Line Tools
  ```bash
  $ xcode-select --install
  ```

2. Install libffi and libsodium
  ```bash
  $ brew install libffi libsodium
  ```

3. Add libffi to your `PKG_CONFIG_PATH`
  ```bash
  $ export PKG_CONFIG_PATH=/usr/local/Cellar/libffi/3.0.13/lib/pkgconfig/
  ```

4. Gem install the client
  ```bash
  $ gem install round
  ```

 [[back]](../README.md)

### Heroku (Coming soon)































