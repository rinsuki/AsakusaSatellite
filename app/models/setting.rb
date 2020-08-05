class Setting
  class << self
    def settings_path
      name = "#{ENV['SETTINGS'] || 'settings'}.yml"
      Rails.root.join('config', name)
    end

    def settings_content
      ENV['SETTINGS_YAML'] || File.read(settings_path)
    end
  end

  @@available_settings = YAML::load(ERB.new(settings_content).result)

  def self.[](key)
    @@available_settings[key.to_s]
  end
end
