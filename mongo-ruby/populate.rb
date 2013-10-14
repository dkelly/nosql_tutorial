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

  def self.store_part_relational(config, db, p)
    doc = {}
    p.header_fields.each do |fld|
      doc[fld.name.to_s] = fld.value.to_s
    end
    doc['user'] = config[:username]
    doc['folder'] = config[:name]
    doc['parts'] = p.parts.collect { |part| store_part_relational(config, db, part) }

    db['parts'].insert(doc)
  end

  def self.to_mongo(config, interaction)
    include Mongo

    cl = MongoClient.new()
    db = cl.db[config[:database_name]]
    collection = db[config[:collection_name]]

    collection.remove({ 'user' => config[:username], 'name' => config[:name] })
    db['parts'].remove({ 'user' => config[:username], 'folder' => config[:name] })

    doc = {
      'user'     => config[:username],
      'name'     => config[:name],
      'messages' => [],
    }

    interaction.progress_start("=>#{config[:name]}", config[:files].length)
    config[:files].each() do |filename|
      doc['messages'] << yield(db, Mail.read(filename))
      interaction.progress_inc()
    end

    collection.insert(doc)
    interaction.progress_finish()
  end

  def self.to_mongo_nested(config, interaction)
    to_mongo(config, interaction) do |db, message|
      store_part_nested(message)
    end
  end

  def self.to_mongo_relational(config, interaction)
    to_mongo(config, interaction) do |db, message|
      store_part_relational(config, db, message)
    end
  end
end
