class Experiment < ActiveYaml::Base
  set_root_path "config/data"
  set_filename "experiments"
  field :id
  field :active
  field :variations

  def bucket_keys
    @bucket_keys ||= variations.keys
  end

  def bucket_size
    @bucket_size ||= bucket_keys.count
  end

  def bucket_for_patient(patient_id)
    bucket_hash = Zlib.crc32(patient_id) % bucket_size
    key = bucket_keys[bucket_hash]
    variations[key]
  end
end
