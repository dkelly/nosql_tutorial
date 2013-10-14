require 'mongo'
require './queries'

include Mongo

user = ARGV[0]
folder = ARGV[1]

if user && folder
  Queries.folder_contents_relational(MongoClient.new, user, folder)
elsif user
  Queries.folders(MongoClient.new, user)
else
  Queries.user_information(MongoClient.new)
end

