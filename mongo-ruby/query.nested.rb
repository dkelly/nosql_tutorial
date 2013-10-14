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
  mailboxes.find({'user' => user}).each() do |doc|
    puts "(#{doc['messages'].length}) #{doc['name']}"
  end
end

def users(mailboxes)
  counts = {}
  folder_counts = mailboxes.aggregate([
                                       { '$group' =>
                                         {
                                           '_id' => '$user',
                                           'count' => { '$sum' => 1 },
                                         },
                                       },
                                      ])
  folder_counts.each() do |user_counts|
    counts[user_counts['_id']] = { :folders => user_counts['count'] }
  end

  message_counts = mailboxes.aggregate([
                                        { '$unwind' => '$messages'},
                                        { '$group' =>
                                          {
                                            '_id' => '$user',
                                            'count' => { '$sum' => 1 },
                                          },
                                        },
                                       ])
  message_counts.each() do |user_counts|
    counts[user_counts['_id']][:messages] = user_counts['count']
  end

  counts.each() do |k, v|
    puts "#{k}: #{v[:folders]} folders, #{v[:messages]} messages"
  end
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

