namespace :admin do
  desc "Create master admin user for production environment"
  task create_master: :environment do
    puts "Creating master admin user..."
    
    email = ENV['MASTER_USER_EMAIL']
    password = ENV['MASTER_USER_PASSWORD']
    name = ENV['MASTER_USER_NAME'] || 'Master Admin'
    
    if email.blank? || password.blank?
      puts "ERROR: Missing required environment variables"
      puts "Please set:"
      puts "- MASTER_USER_EMAIL: Email address for master admin"
      puts "- MASTER_USER_PASSWORD: Secure password for master admin"
      puts "- MASTER_USER_NAME: Display name (optional)"
      exit 1
    end
    
    # Validate password strength
    if password.length < 12
      puts "ERROR: Password must be at least 12 characters long"
      exit 1
    end
    
    begin
      master_user = User.find_or_create_by!(email: email) do |user|
        user.password = password
        user.password_confirmation = password
        user.name = name
      end
      
      # Ensure admin role exists
      admin_role = Role.find_by!(name: 'admin', system_role: true)
      
      # Assign admin role
      unless master_user.roles.include?(admin_role)
        master_user.roles << admin_role
      end
      
      puts "✅ Master user created successfully:"
      puts "   Email: #{email}"
      puts "   Name: #{name}"
      puts "   Roles: #{master_user.roles.pluck(:name).join(', ')}"
      puts ""
      puts "Master user can now access the admin panel at /admin"
      
    rescue => e
      puts "❌ Failed to create master user: #{e.message}"
      exit 1
    end
  end
  
  desc "Generate secure password for master user"
  task generate_password: :environment do
    require 'securerandom'
    
    # Generate a secure password with mixed characters
    password = SecureRandom.urlsafe_base64(18)
    
    puts "Generated secure password for master user:"
    puts "MASTER_USER_PASSWORD=#{password}"
    puts ""
    puts "Add this to your environment variables and run:"
    puts "MASTER_USER_EMAIL=admin@yourdomain.com \\"
    puts "MASTER_USER_PASSWORD=#{password} \\"
    puts "MASTER_USER_NAME='Master Admin' \\"
    puts "bin/rails admin:create_master"
  end
  
  desc "Reset master user password (interactive)"
  task reset_password: :environment do
    require 'io/console'
    
    print "Enter master user email: "
    email = STDIN.gets.chomp
    
    user = User.find_by(email: email)
    unless user
      puts "❌ User not found: #{email}"
      exit 1
    end
    
    admin_role = Role.find_by(name: 'admin', system_role: true)
    unless user.roles.include?(admin_role)
      puts "❌ User #{email} is not an admin"
      exit 1
    end
    
    print "Enter new password: "
    password = STDIN.noecho(&:gets).chomp
    puts
    
    print "Confirm password: "
    password_confirmation = STDIN.noecho(&:gets).chomp
    puts
    
    if password != password_confirmation
      puts "❌ Passwords do not match"
      exit 1
    end
    
    if password.length < 12
      puts "❌ Password must be at least 12 characters long"
      exit 1
    end
    
    user.update!(password: password, password_confirmation: password)
    puts "✅ Password updated successfully for #{email}"
  end
end