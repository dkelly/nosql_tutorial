require 'gmail'
require 'fileutils'

module Download
  def self.from_gmail(config, interaction)
    if config.key?(:folders) && config[:folders].length > 0
      folders_to_download = config[:folders].select() do |folder|
        !File.directory?(folder[:local])
      end
      
      if (folders_to_download.length > 0)
        pass = interaction.get_password()
        Gmail.new(config[:username], pass) do |conn|
          conn.peek = true
          folders_to_download.each() do |folder|
            mailbox = conn.mailbox(folder[:remote])
            count = (!config.key?(:count) || config[:count] == 'all') ? mailbox.count : config[:count]
            count = [count, mailbox.count].min
            
            FileUtils.mkdir_p(folder[:local]) 
            interaction.progress_start("<=#{folder[:remote]}", count)
            message_no = 1
            mailbox.emails.first(count).each() do |message|
              filename = "#{folder[:local]}/#{message_no}.mime"
              File.open(filename, 'w+') do |of|
                of.write(message.raw_source)
              end
              interaction.progress_inc()
              message_no += 1
            end
            interaction.progress_finish()
          end
        end
      end

      config[:folders].each() do |folder|
        yield({
                :username      => config[:username],
                :remote_folder => folder[:remote],
                :files         => Dir.glob("#{folder[:local]}/*.mime"),
              })
      end
    end
  end
end
