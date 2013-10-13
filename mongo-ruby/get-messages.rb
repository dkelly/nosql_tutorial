require 'highline/import'
require 'progressbar'
require 'gmail'
require 'fileutils'

(user, folder) = ARGV

user = ask('User: ') if !user
pass = ask('Pass: ') { |q| q.echo = false }
folder = ask('Folder: ') if !folder

Gmail.new(user, pass) do |gmail|
  gmail.peek = true
  f = gmail.mailbox(folder)
  progress = ProgressBar.new('Message: ', 100)

  FileUtils.mkdir_p('messages') if !File.directory? 'messages'

  step = 0
  f.emails.first(100).each do |m|
    progress.set(step)
    File.open("messages/#{step}.mime", 'w+') do |of|
      of.write(m.raw_source())
    end
    step = step + 1
  end
  
  progress.finish()
end


