# What is Bitnami CLI

  ```
  ! Experimental

  The Bitnami CLI is currently for experimentation. Please provide feedback by logging issues in our GitHub repo.
  ```

The Bitnami CLI simplifies operations with the docker compose based Bitnami apps published on GitHub and is available on all the OS that supports Docker. Additionally, the CLI simplifies updating and executing the different apps we have packaged as Docker containers.


# Install

You can install the Bitnami CLI scripts from the Bitnami GitHub repo. Windows users will need to first install git for Windows.

  LINUX
  ```
  $ curl -sL https://raw.githubusercontent.com/jloramas/bitcli/master/bitcli.sh > bitcli
  $ chmod 755 bitcli && mv bitcli /usr/local/bin/
  ```

  WINDOWS
  ```
  # You need both bitcli.bat and bitcli.sh
  curl -sL https://raw.githubusercontent.com/jloramas/bitcli/master/bitcli.sh > bitcli.sh
  curl -sL https://raw.githubusercontent.com/jloramas/bitcli/master/bitcli.bat > bitcli.bat
  # Add the files to your PATH
  set PATH=<path-to-bitcli>;%PATH%
  ```

# Use

You just need to indicate the application name and what you want to do with it:

  ```
  # To start a Wordpress server application
  bitcli wordpress start

  # To stop the Wordpress server
  bitcli wordpress stop
  ```

  Usage
  ```
  bitcli <application> <COMMAND> [--force]
    start                              Starts <application> 
    stop                               Stops <application> 
    restart                            Restart <application>
    volumes                            Clear existing volumes for <application>
    info                               Shows <application> docker-compose file and debug info
    update [--force]                   Update base image (--force first deletes it)
    compose <commands>                 Execute docker-compose for the <appliction> with the <commands> as parameters 

    --force                            Force always the download of the <application> docker compose file
```

