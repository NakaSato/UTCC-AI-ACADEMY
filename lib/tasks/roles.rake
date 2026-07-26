# Granting the first staff account is a chicken-and-egg problem: /admin is the
# only screen that grants a role, and only an admin can open it. db/seeds.rb
# creates one but is fenced to `Rails.env.local?`, so in production these tasks
# are the only way in.
#
#   bin/rails admin:create
#   bin/rails instructor:create
#   ADMIN_STUDENT_ID=… ADMIN_NAME=… ADMIN_PASSWORD=… bin/rails admin:create
#   INSTRUCTOR_STUDENT_ID=… INSTRUCTOR_NAME=… INSTRUCTOR_PASSWORD=… bin/rails instructor:create
#
# Each prompts when attached to a terminal and reads the environment when not, so
# the same task works over `kamal app exec`. An account that already exists is
# promoted rather than duplicated.
module RoleTask
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

  # `holds` is what already counts as having the role, and it is not always the
  # matching predicate. For instructor it is `staff?`: admin is a superset, so
  # granting instructor to an admin would be a demotion — and demoting the only
  # admin is the one way to leave the app without one.
  def grant(role, env:, holds:)
    student_id = ask("Student ID", "#{env}_STUDENT_ID")
    user = User.find_by(student_id: student_id)

    if user&.public_send(holds)
      puts "#{user.name} (#{user.student_id}) is already an #{user.role}."
      puts "An admin already has #{role} access, so the account is unchanged." unless user.role == role
    elsif user
      report(user) unless user.update(role: role)
      puts "Promoted #{user.name} (#{user.student_id}) to #{role}."
    else
      user = User.new(student_id: student_id, role: role,
                      name: ask("Name", "#{env}_NAME"),
                      password: ask_secret("Password", "#{env}_PASSWORD"))

      report(user) unless user.save
      puts "Created #{role} #{user.name} (#{user.student_id})."
    end
  end
end

namespace :admin do
  desc "Create an admin account, or promote an existing one to admin"
  task create: :environment do
    RoleTask.grant("admin", env: "ADMIN", holds: :admin?)
  end
end

namespace :instructor do
  desc "Create an instructor account, or promote an existing one to instructor"
  task create: :environment do
    RoleTask.grant("instructor", env: "INSTRUCTOR", holds: :staff?)
  end
end
