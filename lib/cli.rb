require "yaml"

class CLI
  attr_accessor :args,
    :cmd,
    :options,
    :config_root,
    :local_config_path

  def initialize(args)
    self.cmd = args.first.to_sym
    self.options = { home: File.expand_path("~") }
    self.args = args
    self.config_root = "#{ENV["HOME"]}/.config"
    self.local_config_path = "#{self.config_root}/loadout.yml"
    puts self.cmd
    parse_options!
  end

  def home
    self.options[:home]
  end

  def verbose?
    self.options[:verbose]
  end

  def fresh?
    self.options[:fresh]
  end

  def nuke?
    self.options[:nuke]
  end

  def dry?
    self.options[:dry]
  end

  def storage_drive
    self.options[:storage]
  end

  def working_drive
    self.options[:working]
  end

  def local_config?
    File.file?(self.local_config_path)
  end

  def valid?
    !self.options[:storage].nil? &&
    !self.options[:working].nil? &&
    !self.options[:home].nil?
  end

  def bootstrap?
    self.options[:boostrap]
  end

  def local_config
    if local_config?
      YAML.load(File.read(self.local_config_path))["loadout"]
    else
      {}
    end
  end

  def to_s
    <<~CLI
    Arguments:
    #{self.args.join(", ")}

    Options:
    #{self.options}

    Local config:
    #{self.local_config}
    CLI
  end

  def parse_options!
    self.local_config.each_pair do |k, v|
      self.options[k.to_sym] = v
    end

    OptionParser.new do |opts|
      opts.banner = "Usage: loadout -f -h /media/external/dir"
      opts.on("-s", "--storage STORAGE", "Drive to use for STORAGE files")
      opts.on("-w", "--working WORKING", "Drive to use for WORKING files")
      opts.on("-h", "--home HOME", "Directory containing HOME env files")
      opts.on("-f", "--fresh", "Cleans existing files")
      opts.on("-v", "--verbose", "Verbose mode")
      opts.on("-d", "--dry-run", "Dry run")
      opts.on("-n", "--nuke", "Nuke the destination (clean state for fresh install).")
      opts.on("-y", "--yes", "Answer yes to all prompts (non-interactive mode)")
      opts.on("-b", "--bootstrap", "Boostrap the computer with apps")
    end.parse!(into: self.options)
  end

  def output(line)
    puts "#{line}"
  end

  def output_cmd(cmd)
    "--> #{cmd}"
  end

  def ask?(question, default: "Y", skip: false)
    if skip
      yield true if block_given?
    else
      prompt = default.match(/y/i) ? "(Y/n)" : "(y/N)"
      puts
      puts "#{question}?: #{prompt}"
      response = gets.chomp
      boolean = response == "" || response.match?(/^y/i)
      yield boolean if block_given?
    end
  end
end
