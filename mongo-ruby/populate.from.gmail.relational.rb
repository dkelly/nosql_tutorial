require 'highline/import'
require 'progressbar'

require './download'
require './populate'

class Interaction
  def get_password
    ask('Pass:') { |q| q.echo = false }
  end
  
  def progress_start(msg, size)
    @progress = ProgressBar.new(msg, size)
  end

  def progress_inc
    @progress.inc()
  end

  def progress_finish
    @progress.finish()
  end
end

user = ARGV[0]
count_s = ARGV[1]
folders = ARGV[2..-1]

user = ask('User: ') if !user
count_s = ask('Count: ') if !count_s
folders << ask('Folder: ') if !folders.length

download_config = {
  :username => user,
  :count    => count_s.to_i(),
  :folders  => folders.collect() do |remote|
    local = "messages/#{user}/#{remote}"
    { :remote => remote, :local => local }
  end
}
  
Download.from_gmail(download_config, Interaction.new()) do |downloads|
  Populate.to_mongo_relational({
                                 :database_name   => 'mail',
                                 :collection_name => 'mailboxes',
                                 :username        => downloads[:username],
                                 :name            => downloads[:remote_folder],
                                 :files           => downloads[:files],
                               }, Interaction.new());
end
