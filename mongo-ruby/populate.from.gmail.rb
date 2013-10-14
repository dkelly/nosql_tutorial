require 'highline/import'
require 'progressbar'
require 'gmail'
require 'fileutils'
require 'mongo'
require 'mail'

include Mongo

def store_part(db, p)
  doc = {}
  p.header_fields.each do |fld|
    doc[fld.name.to_s] = fld.value.to_s
  end
  doc['parts'] = p.parts.collect { |part| store_part(db, part) }

  doc
end

user = ARGV[0]
count_s = ARGV[1]
folders = ARGV[2..-1]

user = ask('User: ') if !user
count_s = ask('Count: ') if !count_s
folders << ask('Folder: ') if !folders.length

count = 0

download_folders = []
folders.each() do |folder|
  download_folder = "messages/#{folder}"
    if !File.directory?(download_folder)
      FileUtils.mkdir_p(download_folder) 
      download_folders << { :download_folder => download_folder, :folder => folder }
    end
end

if download_folders.length > 0
  pass = ask('Pass: ') { |q| q.echo = false }
  Gmail.new(user, pass) do |gmail|
    gmail.peek = true
    download_folders.each() do |info|
      f = gmail.mailbox(info[:folder])
      count = ('all' == count_s) ? f.count : count_s.to_i
      count = [f.count, count].min()
      
      progress = ProgressBar.new("<=#{info[:folder]}", count)
      step = 1
      f.emails.first(count).each do |m|
        File.open("#{info[:download_folder]}/#{step}.mime", 'w+') do |of|
          of.write(m.raw_source)
        end
        progress.inc()
        step = step + 1
      end
    end
  end
end

cl = MongoClient.new
db = cl.db['mail']
mailboxes = db['mailboxes']

folders.each() do |folder|
  mailboxes.remove({'user' => user, 'name' => folder})

  doc = {
    'user' => user,
    'name' => folder,
    'messages' => []
  }

  progress = ProgressBar.new("=>#{folder}", count)  
  Dir.glob("messages/#{folder}/*.mime") do |data|
    m = Mail.read(data)
    doc['messages'] << store_part(db, m)
    progress.inc()
  end
  
  mailboxes.insert(doc)
  progress.finish()
end

