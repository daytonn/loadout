require "awesome_print"

class Loadout
  attr_accessor :config

  def initialize(config)
    self.config = config
  end

  def bash_files
    [".env", ".aliases", ".functions", ".bashrc"]
  end

  def get_path(link)
    case link["destination"]
    when "storage"
      "#{self.config[:storage]}/#{link["name"]}"
    when "working"
      "#{self.config[:working]}/#{link["name"]}"
    else
      "#{self.config[:storage]}/#{link["name"]}"
    end
  end

  def apps
    [
      {
        name: "git",
        steps: [
          "add-apt-repository ppa:git-core/ppa",
          "sudo apt update",
          "sudo apt install -y git"
        ]
      }
    ]
  end

  def links
    self.config[:links].map do |link|
      path = get_path(link)
      destination = "#{self.config[:home]}/#{link["name"]}"
      {
        name: link["name"],
        path: path,
        destination: destination,
        exists?: File.directory?(destination)
      }
    end
  end

  def env_files
    self.config[:env].map do |file|
      destination = "#{self.config[:home]}/#{file}"
      {
        destination: destination,
        file: file,
        path: "#{self.config[:working]}/#{file}",
        exists?: File.symlink?(destination)
      }
    end
  end

  def nuke!
    links.each do |link|
      File.unlink(link[:destination]) if link[:exists?]
    end

    env_files.each do |env|
      File.unlink(env[:destination]) if env[:exists?]
    end
  end

  def create_link!(link)
    File.symlink(link[:path], link[:destination])
    File.symlink?(link[:destination])
  end

  def bootstrap
    %[sudo add-apt-repository ppa:git-core/ppa]
    %[sudo apt update]
    %[sudo apt upgrade -y]
    %[sudo apt install -y git]
  end
end
