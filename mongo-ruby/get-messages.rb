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

(user, folder) = ARGV

user = ask('User: ') if !user
pass = ask('Pass: ') { |q| q.echo = false }
folder = ask('Folder: ') if !folder

cl = MongoClient.new
db = cl.db['mail']
mailboxes = db['mailboxes']
mailboxes.remove({'username' => user, 'name' => folder})

Gmail.new(user, pass) do |gmail|
  gmail.peek = true
  f = gmail.mailbox(folder)

  doc = {
    'user' => user,
    'name' => folder,
    'messages' => []
  }

  if !File.directory? 'messages'
    FileUtils.mkdir_p('messages') 
    progress = ProgressBar.new('Download: ', 100)
    step = 1
    f.emails.first(100).each do |m|
      progress.set(step)
      File.open("messages/#{step}.mime", 'w+') do |of|
        of.write(m.raw_source)
      end
      step = step + 1
    end
  end

  progress = ProgressBar.new('Store: ', 100)  
  step = 1
  Dir.glob('messages/*.mime') do |data|
    m = Mail.read(data)
    doc['messages'] << store_part(db, m)
    progress.set(step)
    step = step + 1
  end
  
  mailboxes.insert(doc)
  progress.finish()
end


