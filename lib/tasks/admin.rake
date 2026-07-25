# Bootstrapping the first admin is a chicken-and-egg problem: /admin is the only
# screen that grants a role, and only an admin can open it. db/seeds.rb creates
# one but is fenced to `Rails.env.local?`, so in production this task is the only
# way in.
#
#   bin/rails admin:create
#   ADMIN_STUDENT_ID=… ADMIN_NAME=… ADMIN_PASSWORD=… bin/rails admin:create
#
# It prompts when attached to a terminal and reads the environment when not, so
# the same task works over `kamal app exec`. An account that already exists is
# promoted rather than duplicated.
module AdminTask
  module_function

  def ask(label, env)
    ENV[env].presence || interactive(label, env) do
      print "#{label}: "
      $stdin.gets
    end
  end

  # getpass rather than noecho: it turns the echo off *before* writing the
  # prompt, so a password arriving the same instant still never appears.
  def ask_secret(label, env)
    ENV[env].presence || interactive(label, env) do
      require "io/console"
      $stdin.getpass("#{label}: ")
    end
  end

  def interactive(label, env)
    abort "#{label} is required — set #{env} when running without a terminal." unless $stdin.tty?

    yield.to_s.strip
  end

  def report(user)
    abort [ "Could not save the account:", *user.errors.full_messages.map { "  - #{it}" } ].join("\n")
  end
end

namespace :admin do
  desc "Create an admin account, or promote an existing one to admin"
  task create: :environment do
    student_id = AdminTask.ask("Student ID", "ADMIN_STUDENT_ID")
    user = User.find_by(student_id: student_id)

    if user&.admin?
      puts "#{user.name} (#{user.student_id}) is already an admin."
    elsif user
      AdminTask.report(user) unless user.update(role: "admin")
      puts "Promoted #{user.name} (#{user.student_id}) to admin."
    else
      user = User.new(student_id: student_id, role: "admin",
                      name: AdminTask.ask("Name", "ADMIN_NAME"),
                      password: AdminTask.ask_secret("Password", "ADMIN_PASSWORD"))

      AdminTask.report(user) unless user.save
      puts "Created admin #{user.name} (#{user.student_id})."
    end
  end
end
