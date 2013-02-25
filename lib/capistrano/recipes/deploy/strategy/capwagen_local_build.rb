require 'capistrano/recipes/deploy/strategy/base'
require 'tmpdir'

module Capistrano
  module Deploy
    module Strategy
      class CapwagenLocalBuild < Base
        Compression = Struct.new(:extension, :compress_command, :decompress_command)

        def deploy!
          checkout_source
          make_copy_dir
          make_build
          create_revision_file
          compress_build
          distribute!
        ensure
          remove_temporary_files
        end

        # define methods to access the various temporary files and directories
        @@temp_names = [:source_dir, :build_make_file, :copy_dir]
        @@temp_names.each do |name|
          define_method("#{name}") do 
            next instance_variable_get("@#{name}") unless instance_variable_get("@#{name}").nil?
            Dir::Tmpname.create(configuration[:capwagen_tmp_basename]) do |path|
              instance_variable_set("@#{name}", path)
            end
          end
          private name
        end

        private
          # Get the source of the projects from the repository.
          def checkout_source
            system(source.export(revision, source_dir))
          end

          # Create the directory where our build is generated and our archive is
          # created.
          def make_copy_dir
            system("mkdir #{copy_dir}")
          end

          # Perform the Kraftwagen build
          def make_build
            execute = []
            execute << "#{drush_cmd} kw-generate-makefile #{build_make_file} #{source_dir}"
            execute << "#{drush_cmd} make #{build_make_file} #{build_dir} --concurrency=1"
            system(execute.join(" && "))
          end

          # Add a revision file to the build, to make sure we can find out later
          # which revision we created the build from.
          def create_revision_file
            File.open(File.join(build_dir, "REVISION"), "w") { |f| f.puts(revision) }
          end

          # Create a the archive from the build
          def compress_build
            execute "Compressing #{build_dir} to #{compressed_filename}" do
              Dir.chdir(copy_dir) { system(compress(File.basename(build_dir), File.basename(compressed_filename)).join(" ")) }
            end
          end

          # Upload the archive and the recompress it.
          def distribute!
            upload(compressed_filename, remote_compressed_filename)
            decompress_remote_file
          end

          # Remove the temporary files and directories
          def remove_temporary_files
            execute = []
            @@temp_names.each do |name|
              execute << "rm -Rf #{instance_variable_get("@#{name}")}" unless instance_variable_get("@#{name}").nil?
            end
            system(execute.join(" && ")) unless execute.empty?
          end

          # Find out where the build should be created
          def build_dir
            @build_dir ||= File.join(copy_dir, File.basename(configuration[:release_path]))
          end
          # Find out how the compressed file should be called
          def compressed_filename
            @compressed_filename ||= File.join(copy_dir, "#{File.basename(build_dir)}.#{compression.extension}")
          end
          # Find out to which directory we should upload
          def remote_dir
            @remote_dir ||= configuration[:capwagen_remote_dir] || "/tmp"
          end
          # Find out the name of the compressed file at the server
          def remote_compressed_filename
            @remote_filename ||= File.join(remote_dir, File.basename(compressed_filename))
          end

          # The methods to compress and decompress the files
          def compress(directory, file)
            compression.compress_command + [file, directory]
          end
          def decompress(file)
            compression.decompress_command + [file]
          end
          def compression
            remote_tar = configuration[:capwagen_remote_tar] || 'tar'
            local_tar = configuration[:capwagen_local_tar] || 'tar'

            type = configuration[:capwagen_compression] || :gzip
            case type
            when :gzip, :gz   then Compression.new("tar.gz",  [local_tar, 'czf'], [remote_tar, 'xzf'])
            when :bzip2, :bz2 then Compression.new("tar.bz2", [local_tar, 'cjf'], [remote_tar, 'xjf'])
            else raise ArgumentError, "invalid compression type #{type.inspect}"
            end
          end
          def decompress_remote_file
            run "cd #{configuration[:releases_path]} && #{decompress(remote_compressed_filename).join(" ")} && rm #{remote_compressed_filename}"
          end

          # The methods to execute some commands with error checking
          def execute description, &block
            logger.debug description
            handle_system_errors &block
          end
          def handle_system_errors &block
            block.call
            raise_command_failed if last_command_failed?
          end
          def last_command_failed?
            $? != 0
          end
          def raise_command_failed
            raise Capistrano::Error, "shell command failed with return code #{$?}"
          end
      end
    end
  end
end