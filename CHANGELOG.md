
0.7.1 / 2015-04-20
==================

  * Singular wallet tests / docs
  * Update Changelog v0.7.1
  * Merge pull request #18 from GemHQ/device-admin-tokens
  * Add totp_secret/MFA/App#reset
  * Redo: generate backup keys on all wallet creation
  * Application auth tests
  * Add backup key to application wallet
  * Auth refactor, Admin token
  * Application wallets & user find
  * Docs: reflect token changes, app auth info
  * Python->Ruby import syntax
  * Merge pull request #17 from GemHQ/all-the-tests
  * Delete old / blank specs.
  * Device auth (spec) waits 60 seconds
  * Device_id->Device_token in API
  * Redirect uri can be nil on payment#create
  * Update Docs: coming soons
  * Merge branch 'all-the-tests' of github.com:GemHQ/round-rb into all-the-tests
  * Create user with redirect_uri if it's set
  * Remove spec/round completely.
  * Style: quotes, spacing
  * Style: quotes, spacing
  * +Redirect_Uri to Account#pay & Users#create
  * Change IN INTERFACE device_id->device_token
  * Update Readme with redirect_uri, device_token
  * Remove Readme.bak
  * Mailinator, test MFA loop
  * Add Account.transactions query-ability
  * Style: kwargs, quotes
  * Ruby-fy Docs (Readme, Advanced)
  * Live, HTTP tests for an app & device authed user.
  * remove VCR cassettes
  * Style: Single spaces & implicit returns
  * Utilize keyword arguments more effectively
  * Remove 'eval' usage from association macro
  * Update vcr dependency, -byebug & +pry
  * Clean up Context method signatures and tests
  * Small syntax cleanups. Double quotes bad!
  * remove unnecessary context tests, +TEST #compile_params
  * delete payment & payment generator specs
  * Small style & verbosity improvements
  * Upgrade HTTP dependency from 0.5.1 -> 0.6.0
  * new readme boilerplate from pycli
  * Merge pull request #15 from ksylvest/master
  * changing up the installation to use the bundler helpers so the specific versions don't need to be pinned
  * fixing some dependency issues
  * fixing some dependency issues
  * fixing some dependency issues
  * removing signing key stuff
  * merging master
  * added signing key
  * adding signing certs
  * got transactions working again
  * more catch up to new api version
  * fixes for new api version
  * making sure client gets passed to all new objects
  * switched to saving seeds instead of nodes
  * fixed hash identifier instance method
  * proper versioning structure
  * fixing errors with raising errors
  * a bunch more cleanup
  * subscriptions + a lot of cleanup
  * Merge pull request #14 from GemHQ/update-readme-devicea-auth
  * Merge branch 'feature/1387-add-confirmations-override' into develop
  * Update README.md
  * Merge branch 'feature/interface-improvements' into develop
  * prettying up the interface
  * Update README.md
  * GP-1387 ignore scripts directory for local testing scripts
  * GP-1387 Added confirmations param
  * making sure backup seed gets returned
  * interface improvements for client

0.7.1 / 2015-04-20
==================

  * Merge pull request #18 from GemHQ/device-admin-tokens
  * Add totp_secret/MFA/App#reset
  * Redo: generate backup keys on all wallet creation
  * Application auth tests
  * Add backup key to application wallet
  * Auth refactor, Admin token
  * Application wallets & user find
  * Docs: reflect token changes, app auth info
  * Python->Ruby import syntax
  * Merge pull request #17 from GemHQ/all-the-tests
  * Delete old / blank specs.
  * Device auth (spec) waits 60 seconds
  * Device_id->Device_token in API
  * Redirect uri can be nil on payment#create
  * Update Docs: coming soons
  * Merge branch 'all-the-tests' of github.com:GemHQ/round-rb into all-the-tests
  * Create user with redirect_uri if it's set
  * Remove spec/round completely.
  * Style: quotes, spacing
  * Style: quotes, spacing
  * +Redirect_Uri to Account#pay & Users#create
  * Change IN INTERFACE device_id->device_token
  * Update Readme with redirect_uri, device_token
  * Remove Readme.bak
  * Mailinator, test MFA loop
  * Add Account.transactions query-ability
  * Style: kwargs, quotes
  * Ruby-fy Docs (Readme, Advanced)
  * Live, HTTP tests for an app & device authed user.
  * remove VCR cassettes
  * Style: Single spaces & implicit returns
  * Utilize keyword arguments more effectively
  * Remove 'eval' usage from association macro
  * Update vcr dependency, -byebug & +pry
  * Clean up Context method signatures and tests
  * Small syntax cleanups. Double quotes bad!
  * remove unnecessary context tests, +TEST #compile_params
  * delete payment & payment generator specs
  * Small style & verbosity improvements
  * Upgrade HTTP dependency from 0.5.1 -> 0.6.0
  * new readme boilerplate from pycli
  * Merge pull request #15 from ksylvest/master
  * changing up the installation to use the bundler helpers so the specific versions don't need to be pinned
  * fixing some dependency issues
  * fixing some dependency issues
  * fixing some dependency issues
  * removing signing key stuff
  * merging master
  * added signing key
  * adding signing certs
  * got transactions working again
  * more catch up to new api version
  * fixes for new api version
  * making sure client gets passed to all new objects
  * switched to saving seeds instead of nodes
  * fixed hash identifier instance method
  * proper versioning structure
  * fixing errors with raising errors
  * a bunch more cleanup
  * subscriptions + a lot of cleanup
  * Merge pull request #14 from GemHQ/update-readme-devicea-auth
  * Merge branch 'feature/1387-add-confirmations-override' into develop
  * Update README.md
  * Merge branch 'feature/interface-improvements' into develop
  * prettying up the interface
  * Update README.md
  * GP-1387 ignore scripts directory for local testing scripts
  * GP-1387 Added confirmations param
  * making sure backup seed gets returned
  * interface improvements for client

0.6.0 / 2015-02-16
==================

  * renamed wallet to default_wallet
  * added network mapping to client

0.5.1 / 2015-01-27
==================

  * Moved begin_ and complete_device_authorization to the client object and take a mandatory email argument

0.5.0 / 2014-12-03
==================

  * Initial alpha release
