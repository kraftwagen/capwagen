
require 'capwagen/version'

module Capwagen
  def self.load_into(configuration)
    configuration.load do
      set :drush_cmd, 'drush'

      set :deploy_via, :capwagen_local_build

      set :capwagen_tmp_basename, 'capwagen'
      set :kraftwagen_environment, 'production'

      set :normalize_asset_timestamps, false

      set :drupal_site_name, 'default'
      set(:shared_files) {
        ["sites/#{drupal_site_name}/settings.php",
         "sites/#{drupal_site_name}/settings.local.php"]
      }
      set(:shared_dirs) {
        ["sites/#{drupal_site_name}/files"]
      }

      namespace :deploy do
        # We override the default update task, because we need to add our own 
        # routines between the defaults
        task :update do
          transaction do
            update_code
            find_and_execute_task("drupal:offline")
            create_symlink
            find_and_execute_task("kraftwagen:update")
            find_and_execute_task("drupal:online")
          end
        end

        # We override the default finalize update task, because our logic for 
        # filling projects with the correct symlinks, is completely different from
        # Rails projects.
        task :finalize_update, :except => { :no_release => true } do
          run "chmod -R g+w #{latest_release}" if fetch(:group_writable, true)

          # mkdir -p is making sure that the directories are there for some SCM's that don't
          # save empty folders
          (shared_files + shared_dirs).map do |d|
            if (d.rindex('/')) then
              run "rm -rf #{latest_release}/#{d} && mkdir -p #{latest_release}/#{d.slice(0..(d.rindex('/')))}"
            else
              run "rm -rf #{latest_release}/#{d}"
            end
            run "ln -s #{shared_path}/#{d.split('/').last} #{latest_release}/#{d}"
          end
        end

        task :setup, :except => { :no_release => true } do
          dirs = [deploy_to, releases_path, shared_path]
          dirs += shared_dirs.map { |d| File.join(shared_path, d.split('/').last) }
          run "#{try_sudo} mkdir -p #{dirs.join(' ')}"
          run "#{try_sudo} chmod g+w #{dirs.join(' ')}" if fetch(:group_writable, true)
        end
      end

      # The Drupal namespace contains the commands for Drupal that is not specific
      # to the Kraftwagen update process
      namespace :drupal do
        task :cache_clear, :except => { :no_release => true }, :only => { :primary => true } do
          run "cd #{latest_release} && #{drush_cmd} cache-clear all"
        end
        task :cache_clear_drush do
          run "cd #{latest_release} && #{drush_cmd} cache-clear drush"
        end
        task :offline, :except => { :no_release => true }, :only => { :primary => true } do
          run "cd #{latest_release} && #{drush_cmd} variable-set maintenance_mode 1 --yes"
          cache_clear
        end
        task :online, :except => { :no_release => true }, :only => { :primary => true } do
          run "cd #{latest_release} && #{drush_cmd} variable-set maintenance_mode 0 --yes"
          cache_clear
        end
      end

      # The Kraftwagen namespace contains the Kraftwagen update process
      namespace :kraftwagen do
        task :update do
          apply_module_dependencies
          updatedb
          find_and_execute_task("drupal:cache_clear_drush")
          features_revert
          find_and_execute_task("drupal:cache_clear")
          manifests
          find_and_execute_task("drupal:cache_clear")
        end

        task :apply_module_dependencies do
          run "cd #{latest_release} && #{drush_cmd} kw-apply-module-dependencies #{kraftwagen_environment}"
        end
        task :updatedb do
          run "cd #{latest_release} && #{drush_cmd} updatedb"
        end
        task :features_revert do
          run "cd #{latest_release} && #{drush_cmd} features-revert-all --yes"
        end
        task :manifests do
          run "cd #{latest_release} && #{drush_cmd} kw-manifests #{kraftwagen_environment}"
        end
      end

    end
  end
end

Capistrano::Configuration.instance.load do
  set :drush_cmd, 'drush'

  set :deploy_via, :capwagen_local_build

  set :capwagen_tmp_basename, 'capwagen'
  set :kraftwagen_environment, 'production'

  set :normalize_asset_timestamps, false

  set :drupal_site_name, 'default'
  set(:shared_files) {
    ["sites/#{drupal_site_name}/settings.php",
     "sites/#{drupal_site_name}/settings.local.php"]
  }
  set(:shared_dirs) {
    ["sites/#{drupal_site_name}/files"]
  }

  namespace :deploy do
    # We override the default update task, because we need to add our own 
    # routines between the defaults
    task :update do
      transaction do
        update_code
        find_and_execute_task("drupal:offline")
        create_symlink
        find_and_execute_task("kraftwagen:update")
        find_and_execute_task("drupal:online")
      end
    end

    # We override the default finalize update task, because our logic for 
    # filling projects with the correct symlinks, is completely different from
    # Rails projects.
    task :finalize_update, :except => { :no_release => true } do
      run "chmod -R g+w #{latest_release}" if fetch(:group_writable, true)

      # mkdir -p is making sure that the directories are there for some SCM's that don't
      # save empty folders
      (shared_files + shared_dirs).map do |d|
        if (d.rindex('/')) then
          run "rm -rf #{latest_release}/#{d} && mkdir -p #{latest_release}/#{d.slice(0..(d.rindex('/')))}"
        else
          run "rm -rf #{latest_release}/#{d}"
        end
        run "ln -s #{shared_path}/#{d.split('/').last} #{latest_release}/#{d}"
      end
    end

    task :setup, :except => { :no_release => true } do
      dirs = [deploy_to, releases_path, shared_path]
      dirs += shared_dirs.map { |d| File.join(shared_path, d.split('/').last) }
      run "#{try_sudo} mkdir -p #{dirs.join(' ')}"
      run "#{try_sudo} chmod g+w #{dirs.join(' ')}" if fetch(:group_writable, true)
    end
  end

  # The Drupal namespace contains the commands for Drupal that is not specific
  # to the Kraftwagen update process
  namespace :drupal do
    task :cache_clear, :except => { :no_release => true }, :only => { :primary => true } do
      run "cd #{latest_release} && #{drush_cmd} cache-clear all"
    end
    task :cache_clear_drush do
      run "cd #{latest_release} && #{drush_cmd} cache-clear drush"
    end
    task :offline, :except => { :no_release => true }, :only => { :primary => true } do
      run "cd #{latest_release} && #{drush_cmd} variable-set maintenance_mode 1 --yes"
      cache_clear
    end
    task :online, :except => { :no_release => true }, :only => { :primary => true } do
      run "cd #{latest_release} && #{drush_cmd} variable-set maintenance_mode 0 --yes"
      cache_clear
    end
  end

  # The Kraftwagen namespace contains the Kraftwagen update process
  namespace :kraftwagen do
    task :update do
      apply_module_dependencies
      updatedb
      find_and_execute_task("drupal:cache_clear_drush")
      features_revert
      find_and_execute_task("drupal:cache_clear")
      manifests
      find_and_execute_task("drupal:cache_clear")
    end

    task :apply_module_dependencies do
      run "cd #{latest_release} && #{drush_cmd} kw-apply-module-dependencies #{kraftwagen_environment}"
    end
    task :updatedb do
      run "cd #{latest_release} && #{drush_cmd} updatedb"
    end
    task :features_revert do
      run "cd #{latest_release} && #{drush_cmd} features-revert-all --yes"
    end
    task :manifests do
      run "cd #{latest_release} && #{drush_cmd} kw-manifests #{kraftwagen_environment}"
    end
  end
end

Capwagen.load_into(Capistrano::Configuration.instance)
