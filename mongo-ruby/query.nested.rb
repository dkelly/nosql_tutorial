require 'mongo'

include Mongo

def folder_contents(mailboxes, user, folder)
  mailboxes.find({ :user => user, :name => folder}).each() do |doc|
    puts "#{doc['name']}:"
    message_no = 1
    doc['messages'].each() do |message|
      puts "#{message_no}: #{message['Subject']}"
      message_no += 1
    end
  end
end

def folders(mailboxes, user)
  mailboxes.find('user' => user).each() do |doc|
    puts "(#{doc['messages'].length}) #{doc['name']}"
  end
end

def users(mailboxes)
  groups = mailboxes.aggregate([{ '$group' => { '_id' => 'users', 'users' => { '$addToSet' => '$user' } } }])
  groups.first()['users'].each() { |name| puts name }
end

user = ARGV[0]
folder = ARGV[1]

cl = MongoClient.new
db = cl.db['mail']

if user && folder
  folder_contents(db['mailboxes'], user, folder)
elsif user
  folders(db['mailboxes'], user)
else
  users(db['mailboxes'])
end

