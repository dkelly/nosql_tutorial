require 'mongo'
require 'mail'

module Populate
  def self.store_part_nested(p)
    doc = {}
    p.header_fields.each do |fld|
      doc[fld.name.to_s] = fld.value.to_s
    end
    doc['parts'] = p.parts.collect { |part| store_part_nested(part) }
    
    doc
  end
  
  def self.to_mongo_nested(config, interaction)
    include Mongo

    cl = MongoClient.new()
    db = cl.db[config[:database_name]]
    collection = db[config[:collection_name]]

    collection.remove({ 'user' => config[:username], 'name' => config[:name] })

    doc = {
      'user'     => config[:username],
      'name'     => config[:name],
      'messages' => [],
    }

    interaction.progress_start("=>#{config[:name]}", config[:files].length)
    config[:files].each() do |filename|
      doc['messages'] << store_part_nested(Mail.read(filename))
      interaction.progress_inc()
    end

    collection.insert(doc)
    interaction.progress_finish()
  end
end
