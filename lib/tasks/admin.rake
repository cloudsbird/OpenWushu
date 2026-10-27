namespace :admin do
  desc "Make an existing account an admin: bin/rails \"admin:grant[email@example.com]\""
  task :grant, [ :email ] => :environment do |_task, args|
    abort "Usage: bin/rails \"admin:grant[email@example.com]\"" if args[:email].blank?

    user = User.find_by(email_address: args[:email].strip.downcase) or abort "No account with email #{args[:email]}. Sign up first."
    user.update!(role: "admin", suspended_at: nil)
    user.verify!
    puts "#{user.display_name} <#{user.email_address}> is now an admin."
  end
end
