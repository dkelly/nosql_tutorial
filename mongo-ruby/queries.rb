require 'mongo'

include Mongo

module Queries
  def self.mailboxes(cl)
    cl.db['mail']['mailboxes']
  end

  def self.folder_contents_nested(cl, user, folder)
    mailboxes(cl).find({ :user => user, :name => folder}).each() do |doc|
      puts "#{doc['name']}:"
      message_no = 1
      doc['messages'].each() do |message|
        puts "#{message_no}: #{message['Subject']}"
        message_no += 1
      end
    end
  end

  def self.folders(cl, user)
    mailboxes(cl).find({'user' => user}).each() do |doc|
      puts "(#{doc['messages'].length}) #{doc['name']}"
    end
  end

  def self.user_information(cl)
    counts = {}
    mailboxes = mailboxes(cl)
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
end
