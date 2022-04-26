class GetBsnlTemplateDetails
  include I18n::Backend::Flatten
  include Memery
  CONFIG_FILE = "config/data/bsnl_templates.yml"
  DUPLICATE_TEMPLATES = {
    "notifications.set03_basic_repeated.first" => "notifications.set03.basic",
    "notifications.set03_basic_repeated.second" => "notifications.set03.basic",
    "notifications.set03_basic_repeated.third" => "notifications.set03.basic"
  }

  attr_reader :template_details, :template_names

  def initialize
    @template_details = Messaging::Bsnl::Api.new.get_template_details
    @template_names = @template_details.map { |template_detail| template_detail["Template_Name"] }
  end

  def write_to_config
    show_templates_pending_naming
    File.open(CONFIG_FILE, "w") do |file|
      file.write("# This is an autogenerated file. Do not modify.\n")
      file.write("# Use get_bsnl_templates.rake to fetch a new copy of this file.\n")
      file.write(massaged_template_details.to_yaml)
    end

    info "Added latest templates list to #{CONFIG_FILE}."
    info "Changes to this file (if any) should be committed to simple-server."
  end

  def massaged_template_details
    template_details.to_h do |template|
      template_name = template["Template_Name"]
      [
        template_name,
        template.slice(
          "Template_Id", "Template_Keys",
          "Non_Variable_Text_Length", "Max_Length_Permitted",
          "Template_Status", "Is_Unicode"
        )
      ]
    end.then { |hsh| add_version_info(hsh) }
      .then { |hsh| insert_duplicate_templates(hsh) }
      .then { |hsh| hsh.sort_by(&:first).to_h }
  end

  def show_templates_pending_naming
    templates_pending_naming = template_details.select { |template_detail| template_detail["Template_Status"] == "0" }

    if templates_pending_naming.any?
      error "⚠️  These templates need to be named on the BSNL dashboard:"
      puts_list templates_pending_naming.map { |template_detail| template_detail["Template_Name"] }
    end
  end

  private

  def error(message)
    puts message.red
  end

  def warning(message)
    puts message.yellow
  end

  def info(message)
    puts message.green
  end

  def puts_list(array)
    puts array.to_yaml.delete_prefix("---\n")
  end

  def add_version_info(config)
    config.to_h do |template_name, template_detail|
      [template_name, template_detail.merge("Version" => Messaging::Bsnl::DltTemplate.version_number(template_name))]
    end.then { |hsh| add_latest_version_name(hsh) }
  end

  def add_latest_version_name(config)
    latest_versions = Hash.new(0)
    latest_version_names = {}

    config.each do |template_name, template_detail|
      version = template_detail["Version"]
      name_without_version = Messaging::Bsnl::DltTemplate.drop_version_number(template_name)

      if version > latest_versions[name_without_version]
        latest_versions[name_without_version] = version
        latest_version_names[name_without_version] = template_name
      end
    end

    config.to_h do |template_name, template_detail|
      name_without_version = Messaging::Bsnl::DltTemplate.drop_version_number(template_name)
      [template_name,
        template_detail.merge(
          "Is_Latest_Version" => (template_detail["Version"] == latest_versions[name_without_version]),
          "Latest_Template_Version" => latest_version_names[name_without_version]
        )]
    end
  end

  def insert_duplicate_templates(config)
    DUPLICATE_TEMPLATES.each do |duplicate_template_name, original_template_name|
      matching_templates = config.select do |template_name, template_details|
        template_name.match?(original_template_name) && template_details["Is_Latest_Version"]
      end

      matching_templates.each do |template_name, details|
        locale_name = template_name.split(".").first

        config["#{locale_name}.#{duplicate_template_name}"] = details
      end
    end
    config
  end
end
