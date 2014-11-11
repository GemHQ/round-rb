class Round::ApplicationCollection < Round::Collection

  def create(options = {})
    app_resource = @resource.create(options)
    app = Round::Application.new(resource: app_resource)
    self.add(app)
    app
  end

  def content_type
    Round::Application
  end

end