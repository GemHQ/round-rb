module Round::TestHelpers::Auth 
  module TestCreds
    API_TOKEN = ENV['GEM_API_TOKEN'] || raise('Set ENV variable: GEM_API_TOKEN')
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

  def app_auth_client
    client = Round.client
    client.authenticate_application(api_token: TestCreds::API_TOKEN)
    client
  end

  def app_auth_user(email: "email#{rand(100..10000).to_s}@mailinator.com")
    puts "App auth user created with at #{email}"
    app_auth_client.users.create(
      first_name: TestCreds::FIRST_NAME, 
      last_name: TestCreds::LAST_NAME, 
      passphrase: TestCreds::PASSPHRASE, 
      email: email,
      device_name: TestCreds::DEVICE_NAME
    )
  end

  def device_auth_user
    device_id, user = app_auth_user(email: random_email)
    3.times do 
      puts 'This will sleep for 45 seconds while you complete the steps in your email.'
      puts 'If thou dost not complete this, thine tests shall fail.'
      sleep 45
      begin
        return app_auth_client.authenticate_device(
          api_token: TestCreds::API_TOKEN,
          device_id: device_id,
          email: user.email
        )
      rescue
      end
    end
  end
end
