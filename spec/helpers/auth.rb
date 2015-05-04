module Round::TestHelpers::Auth 
  module TestCreds
    API_TOKEN = ENV['GEM_API_TOKEN'] || raise('Set ENV variable: GEM_API_TOKEN')
    ADMIN_TOKEN = ENV['GEM_ADMIN_TOKEN'] || raise('Set ENV var: GEM_ADMIN_TOKEN')
    TOTP_SECRET = ENV['GEM_TOTP_SECRET'] || raise('Set ENV var: GEM_TOTP_SECRET')
    EMAIL = ENV['GEM_EMAIL']
                #ayn 
    PASSPHRASE = rand(1000..1000000).to_s
    LAST_NAME = rand(1000..1000000).to_s
    FIRST_NAME = rand(1000..1000000).to_s
    DEVICE_NAME = "device#{rand(100..100000).to_s}"
  end

  def random_email
    e = TestCreds::EMAIL.split('@')
    e[0] << "+roundrbtest#{rand(1..1000000)}"
    e = e.join('@')
    puts "User email: #{e}"
    e
  end

  def identify_auth_client
    #client = Round.client(:bitcoin_testnet)
    client = Round.client(:bitcoin_testnet, 'https://api-sandbox.gem.co/')
    client.authenticate_identify(
      api_token: TestCreds::API_TOKEN
    )
    client
  end

  def app_auth_client
    client = identify_auth_client
    app = client.authenticate_application(
      api_token: TestCreds::API_TOKEN,
      admin_token: TestCreds::ADMIN_TOKEN
    )
    app.totp = TestCreds::TOTP_SECRET
    [app, client]
  end

  def identify_auth_user(email: "email#{rand(100..10000).to_s}@mailinator.com")
    puts "App auth user created with at #{email}"
    identify_auth_client.users.create(
      first_name: TestCreds::FIRST_NAME, 
      last_name: TestCreds::LAST_NAME, 
      passphrase: TestCreds::PASSPHRASE, 
      email: email,
      device_name: TestCreds::DEVICE_NAME
    )
  end

  def device_auth_user
    email = random_email
    device_token = identify_auth_user(email: email)
    puts 'This will sleep for 60 seconds while you complete the steps in your email.'
    puts 'If thou dost not complete this, thine tests shall fail.'
    sleep 60
    identify_auth_client.authenticate_device(
      api_token: TestCreds::API_TOKEN,
      device_token: device_token,
      email: email
    )
  end
end
