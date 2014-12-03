module Round
  class ApplicationCollection < Round::Collection

    def create(name, callback_url = nil)
      params = { name: name }
      params.merge!(callback_url: callback_url) if callback_url
      app_resource = @resource.create(params)
      app = Round::Application.new(resource: app_resource)
      self.add(app)
      app
    end

    def content_type
      Round::Application
    end

  end
end